package br.com.littlesummit.backend.config;

import br.com.littlesummit.backend.model.Role;
import br.com.littlesummit.backend.model.User;
import br.com.littlesummit.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Inicializador de dados que garante a existência dos usuários padrão (ADM e USUARIO) no banco.
 */
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (!userRepository.existsByUsername("admin")) {
            User admin = User.builder()
                    .name("Administrador")
                    .username("admin")
                    .password(passwordEncoder.encode("admin123"))
                    .role(Role.ADM)
                    .active(true)
                    .build();
            userRepository.save(admin);
        }

        if (!userRepository.existsByUsername("operador")) {
            User operador = User.builder()
                    .name("Operador de Produção")
                    .username("operador")
                    .password(passwordEncoder.encode("operador123"))
                    .role(Role.USUARIO)
                    .active(true)
                    .build();
            userRepository.save(operador);
        }
    }
}