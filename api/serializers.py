from rest_framework import serializers
from .models import ProjectData, BioinformaticsTool, UploadData, History


class ProjectDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectData
        fields = '__all__'


class BioinformaticsToolSerializer(serializers.ModelSerializer):
    class Meta:
        model = BioinformaticsTool
        fields = '__all__'


class UploadDataSerializer(serializers.ModelSerializer):
    project_data = ProjectDataSerializer()
    bioinformatics_tool = BioinformaticsToolSerializer()

    class Meta:
        model = UploadData
        fields = '__all__'


class HistorySerializer(serializers.ModelSerializer):
    upload_data = UploadDataSerializer()

    class Meta:
        model = History
        fields = '__all__'