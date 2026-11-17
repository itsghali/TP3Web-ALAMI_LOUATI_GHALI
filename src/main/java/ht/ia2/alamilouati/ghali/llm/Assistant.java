package ht.ia2.alamilouati.ghali.llm;

import dev.langchain4j.service.Result;

public interface Assistant {
    Result<String> chat(String prompt);
}
