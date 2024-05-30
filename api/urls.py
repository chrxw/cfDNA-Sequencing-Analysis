from django.urls import path
from .views import project_data, get_tools, create_project_data_view, upload_to_gcs, trigger_pipeline, display_history, get_history_data, recent_tools

urlpatterns = [
     path('project-data/', project_data, name='project_data'),

     path('get-tools/', get_tools, name='get_tools'),
     path('create-project-data-view', create_project_data_view, name='create_project_data_view'),
     path('upload-to-gcs/', upload_to_gcs, name='upload_to_gcs'),
     path('trigger-pipeline/', trigger_pipeline, name='trigger_pipeline'),

     path('get_history_data/', get_history_data, name='get_history_data'),
     path('display_history/<str:history_id>/', display_history, name='display_history'),

     path('recent-tools', recent_tools, name='recent_tools'),
]