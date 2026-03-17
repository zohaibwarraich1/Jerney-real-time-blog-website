{{- define "Jerney-real-time-blog-website-chart.labels" -}}
app.kubernetes.io/managed-by: "Helm"
{{- if .Chart.AppVersion }}
app.kubernetes.io/app-version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Chart.Version }}
app.kubernetes.io/chart-version: {{ .Chart.Version | quote }}
{{- end }}
environment: production
{{- end }}
