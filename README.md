# LangChain Agent AWS

Agente de IA con LangGraph desplegado en producción sobre AWS ECS Fargate, con CI/CD via GitHub Actions y gestión de infraestructura con Terraform.

## Stack

- **Agente**: LangGraph (ReAct) + OpenAI GPT-4o-mini
- **UI**: Streamlit
- **Observabilidad**: LangSmith
- **Infra**: AWS ECS Fargate + ECR
- **IaC**: Terraform
- **CI/CD**: GitHub Actions

## Estructura

```
├── agent/                  # LangGraph agent
│   └── graph.py
├── app/                    # Streamlit UI
│   └── streamlit_app.py
├── infra/terraform/        # Infraestructura AWS
│   ├── main.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   └── variables.tf
├── .github/workflows/      # CI/CD
│   ├── ci.yml              # Tests en cada push
│   └── deploy.yml          # Deploy a AWS en push a main
└── Dockerfile
```

## Setup

### 1. Secrets en AWS (una vez, manual)

```bash
aws secretsmanager create-secret --name openai-api-key --secret-string "sk-..."
aws secretsmanager create-secret --name langchain-api-key --secret-string "ls__..."
```

### 2. Secrets en GitHub

En **Settings → Secrets and variables → Actions**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 3. Deploy

Cualquier push a `main` lanza el pipeline automáticamente:
1. Build de imagen Docker
2. Push a ECR
3. `terraform apply` — actualiza ECS con la nueva imagen

### Desarrollo local

```bash
pip install -r requirements.txt
export OPENAI_API_KEY="sk-..."
export LANGCHAIN_API_KEY="ls__..."
export LANGCHAIN_TRACING_V2="true"
streamlit run app/streamlit_app.py
```
