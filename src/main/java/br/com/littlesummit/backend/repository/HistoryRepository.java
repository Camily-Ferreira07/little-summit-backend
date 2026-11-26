package br.com.littlesummit.backend.repository;

import br.com.littlesummit.backend.model.History;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repositório JPA para auditoria de ações realizadas pelos usuários no sistema.
 */
public interface HistoryRepository extends JpaRepository<History, Long> {

    List<History> findAllByOrderByCreatedAtDesc();
}