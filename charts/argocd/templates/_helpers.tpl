{{/*
Expand the name of the chart.
*/}}
{{- define "argocd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argocd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argocd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argocd.labels" -}}
helm.sh/chart: {{ include "argocd.chart" . }}
{{ include "argocd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argocd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "argocd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argocd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Rollout health check Lua script
*/}}
{{- define "argocd.rolloutHealthLua" -}}
argoproj.io/Rollout:
  health.lua: |
    hs = {}
    if obj.status ~= nil then
      if obj.status.phase ~= nil and obj.status.phase == "Healthy" then
        hs.status = "Healthy"
        hs.message = "Rollout is healthy"
        return hs
      end
      if obj.status.conditions ~= nil then
        for i, condition in ipairs(obj.status.conditions) do
          if condition.type == "Healthy" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = condition.message
            return hs
          end
          if condition.type == "Completed" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = "Rollout completed"
            return hs
          end
        end
      end
    end
    hs.status = "Progressing"
    hs.message = "Rollout is progressing"
    return hs
{{- end }}

{{/*
Health check annotations for ingress
*/}}
{{- define "argocd.healthCheckAnnotations" -}}
{{- if .Values.healthCheck.enabled }}
{{- $path := .Values.healthCheck.path | default "/healthz" }}
{{- $protocol := .Values.healthCheck.protocol | default "HTTP" }}
{{- $port := .Values.healthCheck.port | default "traffic-port" }}
healthcheck-path: {{ $path | quote }}
healthcheck-protocol: {{ $protocol | quote }}
healthcheck-port: {{ $port | quote }}
{{- end }}
{{- end }}
