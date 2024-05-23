from django.urls import path
from .views import project_data, upload_file


urlpatterns = [
     path('project-data/', project_data, name='project_data'),
     path('upload/', upload_file, name='upload_file'),
]