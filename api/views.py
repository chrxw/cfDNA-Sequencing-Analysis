import os
import re
import uuid
import json
import logging
import subprocess
import paramiko

from datetime import datetime

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse, HttpResponseBadRequest
from django.db.models import Count, Max
from django.views.decorators.csrf import csrf_exempt, ensure_csrf_cookie
from django.core.exceptions import ValidationError, ObjectDoesNotExist
from django.core.files.storage import default_storage
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.contrib.auth.models import User

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from google.cloud import storage
from google.auth import compute_engine

from .models import ProjectData, UploadData, BioinformaticsTool, Status, History
from .serializers import ProjectDataSerializer, BioinformaticsToolSerializer, HistorySerializer


logger = logging.getLogger(__name__)
client = storage.Client(project='cfdna-sequencing-analysis')

# Generate unique id

def generate_unique_sample_id():
    max_id = ProjectData.objects.all().aggregate(Max('sample_id'))['sample_id__max']
    if max_id:
        max_num = int(max_id[2:])
        new_num = max_num + 1
        return f'sp{new_num:03}'
    else:
        return 'sp001'


def generate_unique_data_id():
    max_id = UploadData.objects.all().aggregate(Max('data_id'))['data_id__max']
    if max_id:
        max_num = int(max_id[2:])
        new_num = max_num + 1
        return f'ud{new_num:03}'
    else:
        return 'ud001'


def generate_unique_history_id():
    max_id = History.objects.all().aggregate(Max('history_id'))['history_id__max']
    if max_id:
        max_num = int(max_id[2:])
        new_num = max_num + 1
        return f'ht{new_num:03}'
    else:
        return 'ht001'


# Save data into Database

## Create ProjectData
# def create_project_data(request):
#     if request.method == 'POST':
#         sample_id = generate_unique_sample_id()
#         sample_name = request.POST.get('sample_name')
#         sample_type = request.POST.get('sample_type')
#         diagnosis_group = request.POST.get('diagnosis_group')
#         entity_type = request.POST.get('entity_type')
        
#         project_data = ProjectData(
#             sample_id=sample_id,
#             sample_name=sample_name,
#             sample_type=sample_type,
#             diagnosis_group=diagnosis_group,
#             entity_type=entity_type
#         )
#         project_data.save()
        
#         return JsonResponse({'status': 'success', 'sample_id': sample_id})

## Create UploadData
def create_upload_data(request):
    if request.method == 'POST':
        data_id = generate_unique_data_id()
        user_id = request.POST.get('user_id')
        user = User.objects.get(id=user_id)
        data = request.POST.get('data')
        file_path = request.POST.get('file_path')
        
        upload_data = UploadData(
            data_id=data_id,
            user=user,
            data=data,
            file_path=file_path
        )
        upload_data.save()
        
        return JsonResponse({'status': 'success', 'data_id': data_id})

## Create History
def create_history(request):
    if request.method == 'POST':
        history_id = generate_unique_history_id()
        history_name = request.POST.get('history_name')
        user_id = request.POST.get('user_id')
        user = User.objects.get(id=user_id)
        tool_id = request.POST.get('tool_id')
        tool = BioinformaticsTool.objects.get(tool_id=tool_id)
        input_data_id = request.POST.get('input_data_id')
        input_data = UploadData.objects.get(data_id=input_data_id)
        status_id = request.POST.get('status_id')
        status = Status.objects.get(status_id=status_id)
        process_file_path = request.POST.get('process_file_path')
        
        history = History(
            history_id=history_id,
            history_name=history_name,
            user=user,
            tool=tool,
            input_data=input_data,
            process_file_path=process_file_path,
            status=status
        )
        history.save()
        
        return JsonResponse({'status': 'success', 'history_id': history_id})



# Home

def project_data(request):
    data = ProjectData.objects.all()
    total_samples = data.count()
    control_samples = data.filter(sample_type='control').count()
    positive_samples = data.filter(sample_type='positive').count()

    tumor_entities = data.values('entity_type').annotate(count=Count('entity_type')).order_by()

    response_data = {
        'total_samples': total_samples,
        'control_samples': control_samples,
        'positive_samples': positive_samples,
        'tumor_entities': list(tumor_entities)
    }
    
    return JsonResponse(response_data)


# Analysis Center

## Cancer Prediction

### Create ProjectData
@csrf_exempt
def create_project_data(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))
            sample_id = generate_unique_sample_id()
            history_id = generate_unique_history_id()
            sample_name = data.get('sample_name', '')
            sample_type = data.get('sample_type', '')
            diagnosis_group = data.get('diagnosis_group', '')
            entity_type = data.get('entity_type', '')
            tool_id = 'tl001'

            user = request.user if request.user.is_authenticated else None

            if not (sample_name and sample_type and diagnosis_group and entity_type):
                return JsonResponse({'status': 'error', 'message': 'All fields are required.'}, status=400)

            # Validate tool_id
            try:
                tool = BioinformaticsTool.objects.get(tool_id=tool_id)
            except BioinformaticsTool.DoesNotExist:
                return JsonResponse({'status': 'error', 'message': 'Invalid tool_id.'}, status=400)

            # Save history data
            status = Status.objects.get(status_id='st001')
            input_data_path = f'gs://csa_upload/Data/{sample_name}'
            process_file_path = f'{input_data_path}/output'

            # Create output directory in GCS if it doesn't exist
            client = storage.Client(project='cfdna-sequencing-analysis')
            bucket = client.bucket('csa_upload')
            output_dir_blob = bucket.blob(f'Data/{sample_name}/output/')
            output_dir_blob.upload_from_string('')

            history = History(
                history_id=history_id,
                history_name=sample_name,
                user=user,
                tool=tool,
                input_data_path=input_data_path,
                process_file_path=process_file_path,
                status=status,
                created_at=timezone.now()
            )
            history.save()
            logger.info(f'History entry created: {history}')

            # Validate history_id
            try:
                history = History.objects.get(history_id=history_id)
            except History.DoesNotExist:
                return JsonResponse({'status': 'error', 'message': 'Invalid tool_id.'}, status=400)

            # Save project data
            project_data = ProjectData(
                sample_id=sample_id,
                sample_name=sample_name,
                sample_type=sample_type,
                diagnosis_group=diagnosis_group,
                entity_type=entity_type,
                history=history
            )
            project_data.save()
            logger.info(f'ProjectData entry created: {project_data}')

            # # Run bioinformatics processing on the Linux VM
            # run_bioinformatics_pipeline(sample_name, history)

            return JsonResponse({
                'status': 'success',
                'sample_id': sample_id,
                'history_id': history_id,
                'message': 'Data saved successfully!'
            })
        
        except Exception as e:
            logger.error(f'Error processing request: {e}')
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)

    return JsonResponse({'message': 'Invalid request method.'}, status=405)


### Upload file to google cloud storage
@csrf_exempt
def upload_to_gcs(request):
    if request.method == 'POST':
        sample_name = request.POST.get('sample_name', '')
        user = request.user if request.user.is_authenticated else None

        if not sample_name:
            return JsonResponse({'status': 'error', 'message': 'Sample name is required.'}, status=400)

        # Create a GCS bucket object
        bucket = client.bucket('csa_upload')

        # Create a directory with the sample name
        directory_blob = bucket.blob(f'Data/{sample_name}/')
        directory_blob.upload_from_string('')  # Create an empty file to represent the directory

        # Handle file upload
        uploaded_files = request.FILES.getlist('files')  # Assuming 'files' is the name of the file input field

        for file in uploaded_files:
            # Create a blob object for each file
            blob = bucket.blob(f'Data/{sample_name}/{file.name}')

            # Upload the file to GCS
            blob.upload_from_file(file)
            file_path = f'gs://csa_upload/Data/{sample_name}/{file.name}'
            data_id = generate_unique_data_id()
            upload_data = UploadData(
                data_id=data_id,
                user=user,
                data=file.name,
                file_path=file_path,
                created_at=timezone.now()
            )
            upload_data.save()

        return JsonResponse({'status': 'success', 'message': 'Files uploaded successfully.'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request method.'}, status=405)


### Run Bioinformatics Pipeline
def run_bioinformatics_pipeline(sample_name, history):
    try:
        # Commands to be executed on the Linux VM
        commands = [
            "conda activate snakemake",
            f"mkdir -p /home/chrwan_ja/input/{sample_name}",
            f"mkdir -p /home/chrwan_ja/output/{sample_name}",
            f"gsutil cp gs://csa_upload/Data/{sample_name}/* /home/chrwan_ja/input/{sample_name}",
            f"snakemake -s /home/chrwan_ja/snakefile/snakemake.smk",
            f"gsutil cp -r /home/chrwan_ja/output/{sample_name}/* gs://csa_upload/Data/{sample_name}/output",
            f"rm -rf /home/chrwan_ja/input/{sample_name}",
            f"rm -rf /home/chrwan_ja/output/{sample_name}"
        ]

        # SSH into the VM and execute the commands
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname='34.124.164.13', username='chrwan.ja', key_filename='id_rsa')

        for command in commands:
            stdin, stdout, stderr = ssh.exec_command(command)
            print(stdout.read().decode())
            print(stderr.read().decode())

        ssh.close()

        # Update the history status to 'Complete'
        complete_status = Status.objects.get(status_id='st002')
        history.status = complete_status
        history.save()

    except Exception as e:
        # Update the history status to 'Stopped'
        stopped_status = Status.objects.get(status_id='st003')
        history.status = stopped_status
        history.save()
        print(f"Error: {e}")


@csrf_exempt
def trigger_pipeline(request):
    if request.method == 'POST':
        try:
            # Debugging output to inspect request body
            print(request.body.decode('utf-8'))

            data = json.loads(request.body.decode('utf-8'))
            sample_name = data.get('sample_name', '')
            history_id = data.get('history_id', '')

            if not sample_name or not history_id:
                return JsonResponse({'status': 'error', 'message': 'Sample name and history ID are required.'}, status=400)

            try:
                history = History.objects.get(history_id=history_id)
            except History.DoesNotExist:
                return JsonResponse({'status': 'error', 'message': 'History not found.'}, status=404)

            run_bioinformatics_pipeline(sample_name, history)

            return JsonResponse({'status': 'success', 'message': 'Pipeline triggered successfully.'})
        
        except Exception as e:
            logger.error(f'Error triggering pipeline: {e}')
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)

    return JsonResponse({'message': 'Invalid request method.'}, status=405)



# History


def get_history_data(request):
    if request.method == 'GET':
        # Retrieve historical data
        history_data = History.objects.all()

        # Prepare response data
        response_data = []
        for history in history_data:
            history_entry = {
                'history_id': history.history_id,
                'history_name': history.history_name,
                'tool': history.tool.package_name,
                'status': history.status.status_name,
                'created_at': history.created_at.strftime('%Y-%m-%d'),
            }
            response_data.append(history_entry)

        return JsonResponse({'history_data': response_data})

    return JsonResponse({'error': 'Invalid request method.'}, status=400)


## Full History page

def display_history(request, history_id):
    if request.method == 'GET':
        try:
            history = History.objects.get(history_id=history_id)
            history_entry = {
                'history_id': history.history_id,
                'sample_name': history.history_name,
                'tool_package': history.tool.package_name,
                'transaction_date': history.created_at.strftime('%Y-%m-%d'),
                'status': history.status.status_name,
                'input_files': history.input_data_path,
                'output_files': history.process_file_path,
            }
            return JsonResponse({'history_data': history_entry})
        except History.DoesNotExist:
            return JsonResponse({'error': 'History not found.'}, status=404)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)


# @csrf_exempt
# def history_data(request):
#     if request.method == 'GET':
#         # Fetch data from cookies or database
#         history_data = get_history_data_from_cookies_or_database(request)
#         if history_data:
#             return JsonResponse({'status': 'success', 'history': history_data})
#         else:
#             return JsonResponse({'status': 'error', 'message': 'History data not found'})


# def get_history_data_from_cookies_or_database(request):
#     sample_name = request.COOKIES.get('sample_name')  # Fetch sample_name from cookies
#     if sample_name:
#         history_obj = get_object_or_404(History, history_name=sample_name)
#         history_data = {
#             'sample_name': history_obj.history_name,
#             'tool_package': history_obj.tool_package,  # Assuming tool_package is a ForeignKey to BioinformaticsTool
#             'transaction_date': history_obj.created_at.strftime('%Y-%m-%d %H:%M:%S'),
#             'status': history_obj.status,  # Assuming status is a ForeignKey to Status
#             'input_files': get_input_files(sample_name),
#             'output_files': get_output_files(sample_name)
#         }
#         return history_data
#     else:
#         return None


# def get_input_files(sample_name):
#     # Logic to fetch input files based on sample_name
#     input_path = f'gs://csa_upload/Data/{sample_name}'
#     input_files = [file for file in os.listdir(input_path) if os.path.isfile(os.path.join(input_path, file))]
#     return input_files


# def get_output_files(sample_name):
#     # Logic to fetch output files based on sample_name
#     output_path = f'gs://csa_upload/Data/{sample_name}/output'
#     output_files = [file for file in os.listdir(output_path) if os.path.isfile(os.path.join(output_path, file))]
#     return output_files


# @ensure_csrf_cookie
# def get_history_data(request):
#     # Check if the tool_id is specified as tl001
#     tool_id = 'tl001'  # Assuming tl001 is the tool_id for Cancer Prediction
#     if request.COOKIES.get('tool_id') != tool_id:
#         return JsonResponse({'status': 'error', 'message': 'Invalid tool'})

#     # Get data from cookies
#     sample_name = request.COOKIES.get('sample_name')
#     tool_package = request.COOKIES.get('tool_package')
#     transaction_date = request.COOKIES.get('transaction_date')
#     status = request.COOKIES.get('status')

#     try:
#         # Get data from the database based on sample_name
#         history_entry = History.objects.get(history_name=sample_name)

#         # Check if the tool_id matches
#         if history_entry.tool.tool_id != tool_id:
#             return JsonResponse({'status': 'error', 'message': 'Tool ID mismatch'})

#         # Prepare response data
#         response_data = {
#             'sample_name': sample_name,
#             'tool_package': tool_package,
#             'transaction_date': transaction_date,
#             'status': status,
#             'input_files': history_entry.input_data_path.split(','),
#             'output_files': history_entry.process_file_path.split(','),
#         }

#         return JsonResponse({'status': 'success', 'history': response_data})
#     except ObjectDoesNotExist:
#         return JsonResponse({'status': 'error', 'message': 'History entry not found'})
#     except Exception as e:
#         return JsonResponse({'status': 'error', 'message': str(e)})
    


