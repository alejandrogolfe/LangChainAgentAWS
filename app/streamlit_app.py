import streamlit as st
from agent.graph import agent

st.set_page_config(
    page_title="AI Agent Demo",
    page_icon="🤖",
    layout="centered",
)

st.title("🤖 AI Agent Demo")
st.caption("LangGraph + OpenAI · Desplegado en AWS ECS · Trazado en LangSmith")

with st.sidebar:
    st.header("ℹ️ Sobre este agente")
    st.markdown("""
    Este agente puede:
    - 🔍 **Buscar** información (simulado)
    - 🧮 **Calcular** expresiones matemáticas

    **Stack:**
    - LangGraph (agente ReAct)
    - OpenAI GPT-4o-mini
    - LangSmith (trazado)
    - Streamlit (UI)
    - AWS ECS Fargate (deploy)
    """)
    if st.button("🗑️ Limpiar conversación"):
        st.session_state.messages = []
        st.rerun()

if "messages" not in st.session_state:
    st.session_state.messages = []

for msg in st.session_state.messages:
    st.chat_message(msg["role"]).write(msg["content"])

if prompt := st.chat_input("Pregúntame algo..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    st.chat_message("user").write(prompt)

    with st.chat_message("assistant"):
        with st.spinner("Pensando..."):
            try:
                result = agent.invoke({"messages": [("human", prompt)]})
                response = result["messages"][-1].content
            except Exception as e:
                response = f"❌ Error: {str(e)}"
        st.write(response)
        st.session_state.messages.append({"role": "assistant", "content": response})
