from django.urls import path, re_path
from .views import project_data, get_tool, create_project_data_view, upload_to_gcs, trigger_pipeline, display_history, get_history_data, download_file, recent_tools

urlpatterns = [
     path('project-data/', project_data, name='project_data'),

     path('tools/<str:tool_id>/', get_tool, name='get_tool'),
     path('create-project-data-view/', create_project_data_view, name='create_project_data_view'),
     path('upload-to-gcs/', upload_to_gcs, name='upload_to_gcs'),
     path('trigger-pipeline/', trigger_pipeline, name='trigger_pipeline'),

     path('get_history_data/', get_history_data, name='get_history_data'),
     path('display_history/<str:history_id>/', display_history, name='display_history'),
     path('download_file/<str:filename>/', download_file, name='download_file'),
     re_path(r'^download_file/(?P<filename>.+)/?$', download_file, name='download_file'),

     path('recent-tools', recent_tools, name='recent_tools'),
]