from flask import Flask, request
from twilio.twiml.messaging_response import MessagingResponse
import openai

app = Flask(__name__)

# Configurar la API Key y el ID del asistente
import os
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
ASSISTANT_ID = "asst_JuGIZXo4JR3hiLKXYCZVEOdi"  # Reemplaza con el ID de tu asistente

client = openai.OpenAI(api_key=OPENAI_API_KEY)

@app.route("/whatsapp", methods=["POST"])
def whatsapp():
    try:
        print("📩 Recibiendo mensaje de WhatsApp...")

        incoming_msg = request.values.get("Body", "").strip()
        sender = request.values.get("From", "")
        print(f"👤 Mensaje de {sender}: {incoming_msg}")

        if not incoming_msg:
            print("⚠️ ERROR: No se recibió mensaje válido.")
            return str(MessagingResponse().message("No entendí tu mensaje."))

        # Usar el asistente entrenado en OpenAI
        print("⏳ Enviando mensaje a tu asistente de OpenAI...")
        thread = client.beta.threads.create()
        message = client.beta.threads.messages.create(
            thread_id=thread.id,
            role="user",
            content=incoming_msg
        )

        run = client.beta.threads.runs.create(
            thread_id=thread.id,
            assistant_id=ASSISTANT_ID
        )

        # Esperar a que el asistente responda
        while run.status in ["queued", "in_progress"]:
            run = client.beta.threads.runs.retrieve(thread_id=thread.id, run_id=run.id)

        messages = client.beta.threads.messages.list(thread_id=thread.id)
        assistant_reply = messages.data[0].content[0].text.value

        print(f"✅ Respuesta del Asistente: {assistant_reply}")

        # Responder a WhatsApp con Twilio
        twilio_response = MessagingResponse()
        twilio_response.message(assistant_reply)

        return str(twilio_response)

    except Exception as e:
        print(f"❌ ERROR en el servidor: {str(e)}")
        return str(MessagingResponse().message("Ocurrió un error en el servidor."))

if __name__ == "__main__":
    app.run(port=5000, debug=True)







    
