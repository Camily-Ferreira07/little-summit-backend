package br.com.littlesummit.backend.repository;

import br.com.littlesummit.backend.model.ProductionOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repositório JPA para consulta e registro de ordens de produção.
 */
public interface ProductionOrderRepository extends JpaRepository<ProductionOrder, Long> {

    List<ProductionOrder> findAllByOrderByCreatedAtDesc();
}