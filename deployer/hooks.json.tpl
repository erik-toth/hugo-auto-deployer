[
  {
    "id": "hugo-deploy",
    "execute-command": "/app/deploy.sh",
    "command-working-directory": "/app",
    "response-message": "Deploy triggered",
    "response-headers": [
      { "name": "Content-Type", "value": "text/plain; charset=utf-8" }
    ],

    "pass-environment-to-command": [
      { "source": "entire-payload",  "envname": "WEBHOOK_PAYLOAD"  },
      { "source": "header",          "name": "X-GitHub-Event",    "envname": "GIT_EVENT"      },
      { "source": "header",          "name": "X-Gitlab-Event",    "envname": "GITLAB_EVENT"   }
    ],

    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "payload-hmac-sha256",
            "secret": "${WEBHOOK_SECRET}",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature-256"
            }
          }
        },
        {
          "or": [
            {
              "match": {
                "type": "value",
                "value": "refs/heads/${GIT_BRANCH}",
                "parameter": { "source": "payload", "name": "ref" }
              }
            },
            {
              "match": {
                "type": "value",
                "value": "${GIT_BRANCH}",
                "parameter": { "source": "payload", "name": "ref" }
              }
            }
          ]
        }
      ]
    }
  },

  {
    "id": "hugo-deploy-gitlab",
    "execute-command": "/app/deploy.sh",
    "command-working-directory": "/app",
    "response-message": "GitLab Deploy triggered.",
    "response-headers": [
      { "name": "Content-Type", "value": "text/plain; charset=utf-8" }
    ],

    "pass-environment-to-command": [
      { "source": "entire-payload", "envname": "WEBHOOK_PAYLOAD" },
      { "source": "header",         "name": "X-Gitlab-Event",   "envname": "GITLAB_EVENT" }
    ],

    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "value",
            "value": "${WEBHOOK_SECRET}",
            "parameter": { "source": "header", "name": "X-Gitlab-Token" }
          }
        },
        {
          "match": {
            "type": "value",
            "value": "refs/heads/${GIT_BRANCH}",
            "parameter": { "source": "payload", "name": "ref" }
          }
        }
      ]
    }
  }
]
