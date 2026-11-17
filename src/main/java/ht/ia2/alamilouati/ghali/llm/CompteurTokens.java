package ht.ia2.alamilouati.ghali.llm;

import dev.langchain4j.model.output.TokenUsage;
import jakarta.enterprise.context.SessionScoped;

import java.io.Serial;
import java.io.Serializable;
import java.util.concurrent.atomic.AtomicLong;

/** Total des tokens déclarés par le modèle pendant toute la session HTTP. */
@SessionScoped
public class CompteurTokens implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    private final AtomicLong total = new AtomicLong();

    public void ajouter(TokenUsage usage) {
        if (usage == null) {
            return;
        }
        long nombre = usage.totalTokenCount() != null
                ? usage.totalTokenCount()
                : valeur(usage.inputTokenCount()) + valeur(usage.outputTokenCount());
        total.addAndGet(nombre);
    }

    public long getTotal() {
        return total.get();
    }

    private static long valeur(Integer nombre) {
        return nombre == null ? 0 : nombre.longValue();
    }
}
