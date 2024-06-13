from django.contrib import admin
from django.shortcuts import render
from django.urls import path, include


def index_view(request):
    return render(request, 'dist/index.html')

def analysis_page(request):
    return render(request, 'src/AnalysisCenter')


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('', index_view, name='index'),
    path('/Analysis', analysis_page, name='analysis_page'),
    path('/Dashboard', index_view, name='index'),
    path('/History', index_view, name='index'),
    path('/Settings', index_view, name='index'),
    path('/CancerPrediction', index_view, name='index'),
    path('/QualityControl', index_view, name='index'),
    path('/Mapping', index_view, name='index'),
    path('/Sorting', index_view, name='index'),
    path('/MarkDuplicates', index_view, name='index'),
    path('/Indexing', index_view, name='index'),
    path('/CNVCalling', index_view, name='index'),
    path('/History2', index_view, name='index'),
]
