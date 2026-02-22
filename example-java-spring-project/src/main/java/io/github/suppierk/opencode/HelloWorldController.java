package io.github.suppierk.opencode;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HelloWorldController {

    @GetMapping("/hello-world")
    public ResponseEntity<String> getHelloWorld() {
        return ResponseEntity.ok("{\"message\": \"Hello, World!\"}");
    }
}