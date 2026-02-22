package io.github.suppierk.opencode;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.setup.MockMvcWebAppContext;
import org.springframework.test.web.servlet.MockMvcBuilders;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;

@SpringBootTest
class HelloWorldControllerTest {

    private MockMvc mockMvc;

    @Test
    void testGetHelloWorld() throws Exception {
        mockMvc = MockMvcBuilders.standaloneSetup(new HelloWorldController()).build();
        
        mockMvc.perform(get("/api/hello-world"))
                .andExpect(status().isOk())
                .andExpect(content().json("{\"message\": \"Hello, World!\"}"));
    }
}