from django.contrib import admin
from .models import User, UploadData, ProjectData

# Register your models here.

admin.site.register(ProjectData)
admin.site.register(UploadData)