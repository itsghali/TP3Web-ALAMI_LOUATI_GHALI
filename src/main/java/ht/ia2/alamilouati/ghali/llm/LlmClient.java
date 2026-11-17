package ht.ia2.alamilouati.ghali.llm;

import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.ChatMessageDeserializer;
import dev.langchain4j.data.message.ChatMessageSerializer;
import dev.langchain4j.memory.ChatMemory;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.google.genai.GoogleGenAiChatModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.Result;
import jakarta.enterprise.context.Dependent;
import jakarta.inject.Inject;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serial;
import java.io.Serializable;

/** Client Gemini propre à la vue JSF dans laquelle il est injecté. */
@Dependent
public class LlmClient implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    private String systemRole;
    private transient Assistant assistant;
    private transient ChatMemory chatMemory;

    @Inject
    private CompteurTokens compteurTokens;

    public LlmClient() {
        initialiserAssistant();
    }

    private void initialiserAssistant() {
        String apiKey = System.getenv("GEMINI_KEY");
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("La variable d'environnement GEMINI_KEY n'est pas définie.");
        }

        ChatModel model = GoogleGenAiChatModel.builder()
                .apiKey(apiKey)
                .modelName("gemini-3.5-flash-lite")
                .build();

        this.chatMemory = MessageWindowChatMemory.withMaxMessages(20);
        this.assistant = AiServices.builder(Assistant.class)
                .chatModel(model)
                .chatMemory(chatMemory)
                .build();
    }

    public void setSystemRole(String systemRole) {
        this.systemRole = systemRole;
        this.chatMemory.clear();
        this.chatMemory.add(SystemMessage.from(this.systemRole));
    }

    public String envoyerMessage(String question) {
        Result<String> resultat = this.assistant.chat(question);
        this.compteurTokens.ajouter(resultat.tokenUsage());
        return resultat.content();
    }

    // La vue peut être sérialisée ; les objets techniques LangChain4j sont reconstruits.
    @Serial
    private void writeObject(ObjectOutputStream output) throws IOException {
        output.defaultWriteObject();
        output.writeObject(ChatMessageSerializer.messagesToJson(this.chatMemory.messages()));
    }

    @Serial
    private void readObject(ObjectInputStream input) throws IOException, ClassNotFoundException {
        input.defaultReadObject();
        String messages = (String) input.readObject();
        initialiserAssistant();
        ChatMessageDeserializer.messagesFromJson(messages).forEach(this.chatMemory::add);
    }
}
