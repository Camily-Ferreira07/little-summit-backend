package br.com.littlesummit.backend.service;

import br.com.littlesummit.backend.dto.UserRequestDTO;
import br.com.littlesummit.backend.dto.UserResponseDTO;
import br.com.littlesummit.backend.exception.BusinessRuleException;
import br.com.littlesummit.backend.exception.ConflictException;
import br.com.littlesummit.backend.exception.ResourceNotFoundException;
import br.com.littlesummit.backend.model.Role;
import br.com.littlesummit.backend.model.User;
import br.com.littlesummit.backend.repository.UserRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional
    public UserResponseDTO create(UserRequestDTO request) {
        validateRequest(request, true);
        String normalizedUsername = request.getUsername().trim();

        if (userRepository.existsByUsername(normalizedUsername)) {
            throw new ConflictException("Já existe um utilizador com o username '" + normalizedUsername + "'.");
        }

        User user = User.builder()
                .name(request.getName().trim())
                .username(normalizedUsername)
                .password(request.getPassword())
                .role(request.getRole() != null ? request.getRole() : Role.USUARIO)
                .active(true)
                .build();

        User saved = userRepository.save(user);
        return new UserResponseDTO(saved);
    }

    @Transactional(readOnly = true)
    public List<UserResponseDTO> findAll() {
        return userRepository.findAll()
                .stream()
                .map(UserResponseDTO::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public UserResponseDTO findById(Long id) {
        return new UserResponseDTO(getUserOrThrow(id));
    }

    @Transactional
    public UserResponseDTO update(Long id, UserRequestDTO request) {
        validateRequest(request, false);
        User user = getUserOrThrow(id);
        String normalizedUsername = request.getUsername().trim();

        if (!user.getUsername().equalsIgnoreCase(normalizedUsername)
                && userRepository.existsByUsername(normalizedUsername)) {
            throw new ConflictException("Já existe um utilizador com o username '" + normalizedUsername + "'.");
        }

        user.setName(request.getName().trim());
        user.setUsername(normalizedUsername);

        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            user.setPassword(request.getPassword());
        }

        if (request.getRole() != null) {
            user.setRole(request.getRole());
        }

        User updated = userRepository.save(user);
        return new UserResponseDTO(updated);
    }

    @Transactional
    public void deactivate(Long id) {
        User user = getUserOrThrow(id);
        user.setActive(false);
        userRepository.save(user);
    }

    private User getUserOrThrow(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilizador com ID " + id + " não encontrado."));
    }

    private void validateRequest(UserRequestDTO request, boolean requirePassword) {
        if (request == null) {
            throw new BusinessRuleException("Os dados do utilizador são obrigatórios.");
        }
        if (request.getName() == null || request.getName().isBlank()) {
            throw new BusinessRuleException("O campo 'name' é obrigatório.");
        }
        if (request.getUsername() == null || request.getUsername().isBlank()) {
            throw new BusinessRuleException("O campo 'username' é obrigatório.");
        }
        if (requirePassword && (request.getPassword() == null || request.getPassword().isBlank())) {
            throw new BusinessRuleException("O campo 'password' é obrigatório.");
        }
    }
}