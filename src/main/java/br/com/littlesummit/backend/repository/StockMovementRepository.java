package br.com.littlesummit.backend.repository;

import br.com.littlesummit.backend.model.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repositório JPA para rastreamento de entradas, saídas e ajustes de estoque.
 */
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    List<StockMovement> findAllByOrderByOccurredAtDesc();

    List<StockMovement> findByMaterialIdOrderByOccurredAtDesc(Long materialId);
}