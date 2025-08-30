{{- define "gist.name" -}}
{{- default .Chart.Name .Values.application.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "gist.fullname" -}}
{{- printf "%s-%s" (include "gist.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
