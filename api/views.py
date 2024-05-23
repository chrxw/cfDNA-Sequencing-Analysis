import os
import mimetypes

from django.http import JsonResponse
from django.db.models import Count
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import ProjectData, UploadData, BioinformaticsTool, History
from .serializers import ProjectDataSerializer, BioinformaticsToolSerializer, HistorySerializer

from google.cloud import storage


## Home

# @api_view(['GET'])
# def project_data_summary(request):
#     total_samples = ProjectData.objects.count()
#     control_samples = ProjectData.objects.filter(sample_type='Control').count()
#     positive_samples = ProjectData.objects.filter(sample_type='Positive').count()

#     diagnosis_groups = ProjectData.objects.values('diagnosis_group').annotate(total=Count('diagnosis_group'))
#     diagnosis_group_data = {group['diagnosis_group']: group['total'] for group in diagnosis_groups}

#     entity_types = ProjectData.objects.values('entity_type').annotate(total=Count('entity_type'))
#     entity_type_data = {entity['entity_type']: entity['total'] for entity in entity_types}

#     data = {
#         'totalSamples': total_samples,
#         'controlSamples': control_samples,
#         'positiveSamples': positive_samples,
#         'diagnosisGroups': diagnosis_group_data,
#         'tumorEntities': entity_type_data
#     }

#     return Response(data)


# class ProjectDataView(APIView):
#     def get(self, request):
#         project_data = ProjectData.objects.all()
#         serializer = ProjectDataSerializer(project_data, many=True)
#         return Response(serializer.data, status=status.HTTP_200_OK)
    

def project_data(request):
    data = ProjectData.objects.all()
    total_samples = data.count()
    control_samples = data.filter(sample_type='control').count()
    positive_samples = data.filter(sample_type='positive').count()

    entity_counts = data.values('entity_type').annotate(count=Count('entity_type')).order_by()

    response_data = {
        'total_samples': total_samples,
        'control_samples': control_samples,
        'positive_samples': positive_samples,
        'tumor_entities': list(entity_counts)
    }
    
    return JsonResponse(response_data)



## Analysis Center

def project_data_summary(request):
    tools = BioinformaticsTool.objects.all().values('tool_id', 'tool_name', 'package_name')
    return JsonResponse(list(tools), safe=False)


### Cancer Prediction

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_selected_tool(request):
    try:
        selected_tool = BioinformaticsTool.objects.first()  # Example logic to get the first tool
        serializer = BioinformaticsToolSerializer(selected_tool)
        return Response(serializer.data)
    except BioinformaticsTool.DoesNotExist:
        return Response({'error': 'Bioinformatics tool not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_history(request):
    serializer = HistorySerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(user=request.user)  # Set the user to the current authenticated user
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#### Upload file

@csrf_exempt
def upload_file(request):
    if request.method == 'POST':
        user = request.user
        workflow_name = request.POST.get('workflow_name')
        file = request.FILES.get('file')

        if not file:
            return JsonResponse({'error': 'No file was uploaded'}, status=400)

        # Check if the user has already uploaded a file for the given workflow
        existing_upload = UploadData.objects.filter(user=user, data=workflow_name).first()
        if existing_upload:
            return JsonResponse({'error': 'You have already uploaded a file for this workflow'}, status=400)

        # Validate file type
        allowed_file_types = ['fastq', 'fastq.gz', 'fasta']
        file_extension = file.name.split('.')[-1].lower()
        if file_extension not in allowed_file_types:
            return JsonResponse({'error': 'Invalid file type. Only .fastq, .fastq.gz, or .fasta files are allowed'}, status=400)

        # Create a unique file path in Google Cloud Storage
        file_path = f"Data/{workflow_name}/{file.name}"

        # Save the file to Google Cloud Storage
        bucket = storage.Client().bucket(os.getenv('GS_BUCKET_NAME'))
        blob = bucket.blob(file_path)
        blob.upload_from_file(file)

        # Create a new UploadData instance
        data_id = generate_unique_data_id()
        upload_data = UploadData.objects.create(
            data_id=data_id,
            user=user,
            data=workflow_name,
            file_path=file_path
        )

        return JsonResponse({'message': 'File uploaded successfully', 'file_path': file_path})
    return JsonResponse({'error': 'Invalid request method'}, status=400)


def generate_unique_data_id():
    # Get the highest existing data_id from the database
    highest_data_id = UploadData.objects.all().order_by('-data_id').first()

    if highest_data_id:
        # Extract the numeric part of the highest data_id and increment it
        new_data_id_number = int(highest_data_id.data_id[2:]) + 1
    else:
        # If no existing data_id, start from 1
        new_data_id_number = 1

    # Pad the new data_id number with zeros and concatenate with 'ud'
    new_data_id = f'ud{str(new_data_id_number).zfill(3)}'
    
    return new_data_id