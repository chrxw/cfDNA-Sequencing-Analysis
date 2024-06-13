import json
import logging
import paramiko
import yaml
import re

from django.utils import timezone
from django.http import JsonResponse, HttpResponse
from django.db.models import Count, Max
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required

from google.cloud import storage

from .models import ProjectData, UploadData, BioinformaticsTool, Status, History


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
def create_project_data(sample_name, sample_type, diagnosis_group, entity_type):
    sample_id = generate_unique_sample_id()
    project_data = ProjectData(
        sample_id=sample_id,
        sample_name=sample_name,
        sample_type=sample_type,
        diagnosis_group=diagnosis_group,
        entity_type=entity_type
    )
    project_data.save()
    return sample_id

## Create UploadData
def create_upload_data(user, file_name, file_path):
    data_id = generate_unique_data_id()
    upload_data = UploadData(
        data_id=data_id,
        user=user,
        data=file_name,
        file_path=file_path,
        created_at=timezone.now()
    )
    upload_data.save()
    return data_id

## Create History
def create_history(sample_name, user, tool):
    history_id = generate_unique_history_id()
    input_data_path = f'Data/{sample_name}'
    process_file_path = f'{input_data_path}/output'
    status = Status.objects.get(status_id='st001')
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
    return history_id



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

## Select Tool
def get_tool(request, tool_id):
    try:
        tool = BioinformaticsTool.objects.get(tool_id=tool_id)
        tool_data = {
            'tool_id': tool.tool_id,
            'tool_name': tool.tool_name,
            'package_name': tool.package_name,
        }
        return JsonResponse(tool_data)
    except BioinformaticsTool.DoesNotExist:
        return JsonResponse({'message': 'Tool not found.'}, status=404)


## Upload file to google cloud storage
@csrf_exempt
def upload_to_gcs(request):
    if request.method == 'POST':
        sample_name = request.POST.get('sample_name', '')
        user = request.user if request.user.is_authenticated else None

        if not sample_name:
            return JsonResponse({'status': 'error', 'message': 'Sample name is required.'}, status=400)

        # Create a GCS bucket object
        client = storage.Client(project='cfdna-sequencing-analysis')
        bucket = client.bucket('csa_upload')

        # Create a directory with the sample name
        directory_blob = bucket.blob(f'Data/{sample_name}/')
        directory_blob.upload_from_string('')

        # Create the output directory
        output_dir_blob = bucket.blob(f'Data/{sample_name}/output/')
        output_dir_blob.upload_from_string('')

        # Handle file upload
        uploaded_files = request.FILES.getlist('files')

        for file in uploaded_files:
            # Create a blob object for each file
            blob = bucket.blob(f'Data/{sample_name}/{file.name}')

            # Upload the file to GCS
            blob.upload_from_file(file)
            file_path = f'Data/{sample_name}/{file.name}'
            create_upload_data(user, file.name, file_path)

        return JsonResponse({'status': 'success', 'message': 'Files uploaded successfully.'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request method.'}, status=405)


## Create project data
logger = logging.getLogger(__name__)

@csrf_exempt
def create_project_data_view(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))
            sample_name = data.get('sample_name', '')
            sample_type = data.get('sample_type', '')
            diagnosis_group = data.get('diagnosis_group', '')
            entity_type = data.get('entity_type', '')
            tool_id = data.get('tool_id', '')

            user = request.user if request.user.is_authenticated else None

            if not (sample_name and sample_type and diagnosis_group and entity_type and tool_id):
                return JsonResponse({'status': 'error', 'message': 'All fields are required.'}, status=400)

            try:
                tool = BioinformaticsTool.objects.get(tool_id=tool_id)
            except BioinformaticsTool.DoesNotExist:
                return JsonResponse({'status': 'error', 'message': 'Invalid tool_id.'}, status=400)

            sample_id = create_project_data(sample_name, sample_type, diagnosis_group, entity_type)
            history_id = create_history(sample_name, user, tool)

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


## Run Bioinformatics Pipeline
def run_bioinformatics_pipeline(sample_name, history):
    try:
        # Create config.yaml with the sample_name
        config = {"workflow_name": sample_name}
        with open("/home/chrwan_ja/config.yaml", "w") as file:
            yaml.dump(config, file)

        # Commands to be executed on the Linux VM
        commands = [
            "source /home/chrwan_ja/anaconda3/bin/activate",
            "conda activate snakemake",
            f"mkdir -p /home/chrwan_ja/input/{sample_name}",
            f"mkdir -p /home/chrwan_ja/output/{sample_name}",
            f"gsutil cp gs://csa_upload/Data/{sample_name}/* /home/chrwan_ja/input/{sample_name}",
            f"snakemake -s /home/chrwan_ja/snakefile/snakemake.smk --configfile /home/chrwan_ja/config.yaml",
            f"gsutil cp -r /home/chrwan_ja/output/{sample_name}/* gs://csa_upload/Data/{sample_name}/output",
            f"rm -rf /home/chrwan_ja/input/{sample_name}",
            f"rm -rf /home/chrwan_ja/output/{sample_name}"
        ]

        # SSH into the VM and execute the commands
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname='34.87.139.45', username='chrwan_ja', key_filename='id_rsa')

        for command in commands:
            print(f"Executing: {command}")
            stdin, stdout, stderr = ssh.exec_command(command)
            stdout_str = stdout.read().decode()
            stderr_str = stderr.read().decode()
            print(f"STDOUT: {stdout_str}")
            print(f"STDERR: {stderr_str}")
            if stderr_str:
                raise Exception(f"Error executing command: {command}\n{stderr_str}")

        ssh.close()

        # Update the history status to 'Complete'
        complete_status = Status.objects.get(status_id='st002')
        history.status = complete_status
        history.save()
        print("Pipeline completed successfully.")

    except Exception as e:
        # Update the history status to 'Stopped'
        stopped_status = Status.objects.get(status_id='st003')
        history.status = stopped_status
        history.save()
        print(f"Pipeline execution failed: {e}")


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


## Full History detail

### Get file from GCS bucket
def list_files(bucket_name, prefix):
    """List all files in the GCS bucket with the given prefix."""
    client = storage.Client(project='cfdna-sequencing-analysis')
    bucket = client.bucket(bucket_name)
    blobs = bucket.list_blobs(prefix=prefix)
    file_paths = []

    for blob in blobs:
        if not blob.name.endswith('/'):  # Exclude directories
            file_paths.append(blob.name)

    return file_paths

### History detail
@csrf_exempt
def display_history(request, history_id):
    if request.method == 'GET':
        try:
            history = History.objects.get(history_id=history_id)
            
            # List input files
            input_files = []
            if history.input_data_path:
                bucket_name = 'csa_upload'
                input_prefix = history.input_data_path
                input_files = list_files(bucket_name, input_prefix)
                # Filter out subdirectories and files from subdirectories
                input_files = [file for file in input_files if file.startswith(input_prefix) and not '/' in file[len(input_prefix):].strip('/')]

            # List output files
            output_files = []
            if history.process_file_path:
                bucket_name = 'csa_upload'
                output_prefix = history.process_file_path
                output_files = list_files(bucket_name, output_prefix)

            history_entry = {
                'history_id': history.history_id,
                'sample_name': history.history_name,
                'tool_package': history.tool.package_name,
                'transaction_date': history.created_at.strftime('%Y-%m-%d'),
                'status': history.status.status_name,
                'input_files': input_files,
                'output_files': output_files,
            }

            return JsonResponse({'history_data': history_entry})
        except History.DoesNotExist:
            return JsonResponse({'error': 'History not found.'}, status=404)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    else:
        return JsonResponse({'message': 'Invalid request method.'}, status=405)
    

def download_file(request, filename):
    storage_client = storage.Client(project='cfdna-sequencing-analysis')
    bucket = storage_client.bucket('csa_upload')
    blob = bucket.blob(filename)
    file_content = blob.download_as_bytes()

    response = HttpResponse(file_content, content_type='application/octet-stream')
    response['Content-Disposition'] = f'attachment; filename={filename}'
    return response


@csrf_exempt
def rename_sample(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            history_id = data.get('history_id')
            new_sample_name = data.get('new_sample_name')

            if not history_id or not new_sample_name:
                return JsonResponse({'error': 'Invalid input'}, status=400)

            # Validate new_sample_name
            if len(new_sample_name) > 50 or not re.match(r'^[a-zA-Z0-9-_]+$', new_sample_name):
                return JsonResponse({'error': 'Invalid sample name'}, status=400)

            history = History.objects.get(history_id=history_id)
            history.history_name = new_sample_name
            history.save()

            return JsonResponse({'success': 'Sample name updated successfully'})

        except History.DoesNotExist:
            return JsonResponse({'error': 'History record not found'}, status=404)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Invalid request method'}, status=405)
        

# Dashboard
@login_required
def recent_tools(request):
    try:
        # Get the 4 most recent history entries for the current user
        recent_history = History.objects.filter(user=request.user).order_by('-created_at')[:4]
        
        # Extract the tool information
        recent_tools = [
            {
                'tool_id': history.tool.tool_id,
                'tool_name': history.tool.tool_name,
                'tool_package': history.tool.package_name,
                'used_on': history.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
            for history in recent_history
        ]
        
        return JsonResponse({'recent_tools': recent_tools})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)