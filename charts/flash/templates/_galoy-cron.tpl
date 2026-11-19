{{/*
The cron Jobs that run the app image with the shared config: the daily cron
(galoy-cronjob.yaml) and the hourly Bridge funds request watcher
(bridge-funds-requests-cronjob.yaml). They take the same env, config mount and
volumes from here so the two cannot drift apart.

containerEnv takes a dict of root (the chart context) and jobname (used for
the tracing service name); volumes takes a dict of root. The output is
indented for a container under jobTemplate.spec.template.spec.containers
(containerEnv) and for that pod spec (volumes).
*/}}
{{- define "galoy.cron.containerEnv" -}}
{{- $root := .root -}}
{{- $jobname := .jobname }}
            env:
            - name: HELMREVISION
              value: {{ $root.Release.Revision | quote }}
            - name: LOGLEVEL
              value: {{ $root.Values.galoy.trigger.logLevel | quote }}

            - name: NETWORK
              value: {{ $root.Values.galoy.network }}

            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: {{ $root.Values.tracing.otelExporterOtlpEndpoint | quote }}
            - name: TRACING_SERVICE_NAME
              value: "{{ $root.Values.tracing.prefix }}-{{ $jobname }}"

            - name: PRICE_HOST
              value: {{ $root.Values.price.realtime.host | quote }}

            - name: PRICE_SERVER_HOST
              value: {{ $root.Values.galoy.dealer.host | quote }}
            - name: PRICE_SERVER_PORT
              value: {{ $root.Values.galoy.dealer.port | quote }}

            - name: TRIGGER_PORT
              value: {{ $root.Values.galoy.trigger.port | quote }}
            - name: WEBSOCKET_PORT
              value: {{ $root.Values.galoy.websocket.port | quote }}

            - name: PROXY_CHECK_APIKEY
              valueFrom:
                secretKeyRef:
                  name: {{ $root.Values.galoy.proxyCheckExistingSecret.name }}
                  key: {{ $root.Values.galoy.proxyCheckExistingSecret.key }}

            - name: LND_PRIORITY
              value: {{ $root.Values.galoy.lndPriority }}

{{/* Databases */}}
{{ include "galoy.mongodb.env" $root | indent 12 }}
{{ include "galoy.redis.env" $root | indent 12 }}

{{/* Bitcoin/LND */}}
{{ include "galoy.lnd1.env" $root | indent 12 }}
{{ include "galoy.bria.env" $root | indent 12 }}
{{ include "galoy.ibex.env" $root | indent 12 }}

{{ include "galoy.kratos.env" $root | indent 12 }}
{{ include "galoy.twilio.env" $root | indent 12 }}

            - name: OATHKEEPER_DECISION_ENDPOINT
              value: http://flash-oathkeeper-api:4456

            - name: SVIX_SECRET
              valueFrom:
                secretKeyRef:
                  name: {{ $root.Values.galoy.svixExistingSecret.name }}
                  key: {{ $root.Values.galoy.svixExistingSecret.secret_key }}

            {{ if $root.Values.galoy.trigger.backups.dropbox.enabled }}
            - name: DROPBOX_ACCESS_TOKEN
              valueFrom:
                secretKeyRef:
                  name: {{ $root.Values.galoy.trigger.backups.dropbox.accessTokenExistingSecret.name | quote }}
                  key: {{ $root.Values.galoy.trigger.backups.dropbox.accessTokenExistingSecret.key | quote }}
            {{ end }}

            {{ if $root.Values.galoy.api.firebaseNotifications.enabled }}
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: "/tmp/service-account.json"
            {{ end }}

            volumeMounts:
            {{ if $root.Values.galoy.api.firebaseNotifications.enabled }}
            - name: firebase-notifications-service-account
              mountPath: /tmp
              readOnly: true
            {{ end }}

            - name: custom-yaml
              mountPath: "/var/yaml/"
{{- end -}}

{{- define "galoy.cron.volumes" -}}
{{- $root := .root }}
          volumes:
          {{ if $root.Values.galoy.api.firebaseNotifications.enabled }}
          - name: firebase-notifications-service-account
            secret:
              secretName: {{ $root.Values.galoy.api.firebaseNotifications.existingSecret.name }}
              items:
              - key: {{ $root.Values.galoy.api.firebaseNotifications.existingSecret.key }}
                path: service-account.json
          {{ end }}

          - name: custom-yaml
            secret:
              secretName: "{{ template "galoy.config.name" $root }}"
{{- end -}}
