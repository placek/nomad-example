# https://www.nomadproject.io/docs/job-specification/job
job "app" {
  datacenters = ["dc1"]

  # https://www.nomadproject.io/docs/schedulers
  type = "service"

  # https://www.nomadproject.io/docs/job-specification/constraint
  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  # https://www.nomadproject.io/docs/job-specification/update
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  # https://www.nomadproject.io/docs/job-specification/migrate
  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  # https://www.nomadproject.io/docs/job-specification/group
  group "db" {
    count = 1

    # https://www.nomadproject.io/docs/job-specification/network
    network {
    mode = "bridge"
      port "db" {
        to = 6379
      }
    }

    # https://www.nomadproject.io/docs/job-specification/service
    service {
      name = "app-redis"
      port = "db"

      # check {
      #   type     = "tcp"
      #   port     = "db"
      #   interval = "10s"
      #   timeout  = "2s"
      # }

      connect {
        sidecar_service {}
      }
    }

    # https://www.nomadproject.io/docs/job-specification/restart
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    # https://www.nomadproject.io/docs/job-specification/ephemeral_disk
    ephemeral_disk {
      size = 300 # 300MB
    }

    # https://www.nomadproject.io/docs/job-specification/task
    task "redis" {
      driver = "docker"
      # kill_timeout = "20s"
      config {
        image = "redis:latest"
        ports = ["db"]
      }

      # https://www.nomadproject.io/docs/job-specification/resources
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    }
  }

  group "web" {
    count = 1

    network {
      port "web" {
        to = 4567
      }
    }

    # https://www.nomadproject.io/docs/job-specification/service
    service {
      name = "app-web"
      port = "web"

      check {
        type     = "tcp"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # https://www.nomadproject.io/docs/job-specification/restart
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "await-app" {
      driver = "docker"

      config {
        image        = "alpine:latest"
        command      = "sh"
        args         = ["-c", "echo -n 'Waiting for service'; until nslookup -port=8600 app-redis.service.consul ${NOMAD_IP_web} 2>&1 >/dev/null; do echo '.'; sleep 2; done"]
        network_mode = "host"
      }

      resources {
        cpu    = 200
        memory = 128
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }

    # https://www.nomadproject.io/docs/job-specification/task
    task "web" {
      driver = "docker"

      template {
        data = <<EOF
{{- if service "app-redis" -}}
{{- with index (service "app-redis") 0 -}}
REDIS_URL=redis://{{ .Address }}:{{ .Port }}/
{{- end -}}
{{- end }}
EOF
        destination = "local/env.txt"
        env = true
      }

      config {
        image = "silquenarmo/nomad-app:latest"
        force_pull = true
        command = "sh"
        args = ["-c", "bundle exec puma -C puma.rb"]
        ports = ["web"]
      }

      # https://www.nomadproject.io/docs/job-specification/resources
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
      # https://www.nomadproject.io/docs/job-specification/artifact
      # https://www.nomadproject.io/docs/job-specification/logs
      # https://www.nomadproject.io/docs/job-specification/template
      # https://www.nomadproject.io/docs/job-specification/vault
    }
    # https://www.nomadproject.io/docs/job-specification/ephemeral_disk
    # https://www.nomadproject.io/docs/job-specification/affinity
    # https://www.nomadproject.io/docs/job-specification/spread
  }
}
