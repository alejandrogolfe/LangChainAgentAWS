from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent
from langchain_core.tools import tool


@tool
def search_web(query: str) -> str:
    """Busca información en internet sobre un tema."""
    # Dummy tool — reemplaza con Tavily o SerpAPI en producción
    return (
        f"[Resultado simulado para: '{query}']\n"
        "Anthropic fue fundada en 2021 por ex-miembros de OpenAI. "
        "LangChain es un framework para construir aplicaciones con LLMs. "
        "LangGraph permite crear agentes con grafos de estado."
    )


@tool
def calculate(expression: str) -> str:
    """Evalúa una expresión matemática simple. Ejemplo: 2 + 2, 10 * 5"""
    try:
        result = eval(expression, {"__builtins__": {}})
        return f"Resultado: {result}"
    except Exception as e:
        return f"Error al calcular '{expression}': {e}"


def create_agent():
    # ChatOpenAI lee OPENAI_API_KEY del entorno automáticamente
    # funciona igual en local (run_local.sh) y en AWS (Secrets Manager)
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0,
    )
    tools = [search_web, calculate]
    agent = create_react_agent(llm, tools)
    return agent


agent = create_agent()
