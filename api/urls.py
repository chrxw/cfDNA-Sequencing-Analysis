from django.urls import path
from .views import project_data, create_project_data, upload_to_gcs, create_upload_data, trigger_pipeline, display_history, get_history_data

urlpatterns = [
     path('project-data/', project_data, name='project_data'),
     path('create-project-data/', create_project_data, name='create_project_data'),
     path('create-upload-data/', create_upload_data, name='create-upload-data'),
     path('upload-to-gcs/', upload_to_gcs, name='upload_to_gcs'),
     path('trigger-pipeline/', trigger_pipeline, name='trigger_pipeline'),
     path('get_history_data/', get_history_data, name='get_history_data'),
     path('display_history/<str:history_id>/', display_history, name='display_history'),

]