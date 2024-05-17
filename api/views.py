from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated  # Add authentication check

from .serializers import ProjectDataSerializer, BioinformaticsToolSerializer, UploadDataSerializer, HistorySerializer
from .models import ProjectData, BioinformaticsTool, UploadData, History

# Create your views here.

## Home

def home(request):
    # Retrieve project data from the database
    project_data = ProjectData.objects.all()
    return render(request, 'dist/index.html', {'project_data': project_data})


class ProjectDataListView(APIView):
    def get(self, request):
        project_data = ProjectData.objects.all()
        serializer = ProjectDataSerializer(project_data, many=True)
        return Response(serializer.data)


class BioinformaticsToolDetailView(APIView):
    permission_classes = [IsAuthenticated]  # Only authenticated users can access

    def get(self, request, pk):
        try:
            tool = BioinformaticsTool.objects.get(pk=pk)
            serializer = BioinformaticsToolSerializer(tool)
            return Response(serializer.data)
        except BioinformaticsTool.DoesNotExist:
            return Response({'error': 'Tool not found'}, status=404)


class UploadDataView(APIView):
    permission_classes = [IsAuthenticated]  # Only authenticated users can upload

    def post(self, request):
        serializer = UploadDataSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)  # Created
        return Response(serializer.errors, status=400)  # Bad request
    

class HistoryListView(APIView):
    permission_classes = [IsAuthenticated]  # Only authenticated users can access

    def get(self, request):
        user = request.user
        history = History.objects.filter(user=user).order_by('-date_used')
        serializer = HistorySerializer(history, many=True)
        return Response(serializer.data)
    



### Upload file (GPT)

# import os
# from django.shortcuts import render, redirect
# from django.conf import settings
# from google.cloud import storage
# from .forms import UploadFileForm
# from .models import UploadedFile

# def handle_uploaded_file(uploaded_file, directory_name):
#     client = storage.Client(credentials=settings.GS_CREDENTIALS)
#     bucket = client.bucket(settings.GS_BUCKET_NAME)
#     blob = bucket.blob(f"{directory_name}/{uploaded_file.name}")
#     blob.upload_from_file(uploaded_file)
#     return blob.public_url

# def upload_file(request):
#     if request.method == 'POST':
#         form = UploadFileForm(request.POST, request.FILES)
#         if form.is_valid():
#             directory_name = form.cleaned_data['name']
#             files = request.FILES.getlist('files')

#             for file in files:
#                 public_url = handle_uploaded_file(file, directory_name)
#                 UploadedFile.objects.create(
#                     name=file.name,
#                     file=public_url,
#                     directory=directory_name
#                 )
#             return redirect('success_url')  # Replace with your success URL
#     else:
#         form = UploadFileForm()
#     return render(request, 'upload.html', {'form': form})
