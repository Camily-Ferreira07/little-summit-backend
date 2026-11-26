package br.com.littlesummit.backend.repository;

import br.com.littlesummit.backend.model.Material;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * Repositório JPA para gerenciamento de insumos e consulta de estoque crítico.
 */
public interface MaterialRepository extends JpaRepository<Material, Long> {

    boolean existsByNameIgnoreCase(String name);

    List<Material> findAllByOrderByNameAsc();

    @Query("SELECT m FROM Material m WHERE m.currentQuantity <= m.minimumQuantity ORDER BY m.name ASC")
    List<Material> findLowStockMaterials();
}