from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator

# Create your models here.

## Data

class UploadData(models.Model):
    data_id = models.CharField(max_length=10, primary_key=True, validators=[
        RegexValidator(regex=r'^ud\d{3}$', message='DataID must start with ud followed by 3 digits')
    ])
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    data = models.CharField(max_length=255)
    file_path = models.CharField(max_length=1024, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.data_id} - {self.data}"



class ProjectData(models.Model):
    sample_id = models.CharField(max_length=10, primary_key=True, validators=[
        RegexValidator(regex=r'^sp\d{3}$', message='SampleID must start with sp followed by 3 digits')
    ])
    sample_name = models.CharField(max_length=255)
    sample_type = models.CharField(max_length=255)
    diagnosis_group = models.CharField(max_length=255)
    entity_type = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.sample_id} - {self.sample_name}"



## History

class BioinformaticsTool(models.Model):
    tool_id = models.CharField(max_length=10, primary_key=True, validators=[
        RegexValidator(regex=r'^tl\d{3}$', message='ToolID must start with tl followed by 3 digits')
    ])
    tool_name = models.CharField(max_length=255)
    tool_description = models.TextField(blank=True)
    tool_version = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.tool_id} - {self.tool_name}"

  

class Status(models.Model):
    status_id = models.CharField(max_length=10, primary_key=True, validators=[
        RegexValidator(regex=r'^st\d{3}$', message='StatusID must start with st followed by 3 digits')
    ])
    status_name = models.CharField(max_length=255)
    status_description = models.TextField(blank=True)

    def __str__(self):
        return f"{self.status_id} - {self.status_name}"



class History(models.Model):
    history_id = models.CharField(max_length=10, primary_key=True, validators=[
        RegexValidator(regex=r'^ht\d{3}$', message='HistoryID must start with ht followed by 3 digits')
    ])
    history_name = models.CharField(max_length=255)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    tool = models.ForeignKey(BioinformaticsTool, on_delete=models.CASCADE)
    input_data = models.ForeignKey(UploadData, on_delete=models.CASCADE)
    process_file_path = models.CharField(max_length=1024, blank=True)
    status = models.ForeignKey(Status, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.history_id} - {self.history_name}"
