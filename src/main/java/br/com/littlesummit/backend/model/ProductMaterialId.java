package br.com.littlesummit.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;

/**
 * Chave primária composta da associação entre Produto e Material.
 */
@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class ProductMaterialId implements Serializable {

    @Column(name = "product_id")
    private Long productId;

    @Column(name = "material_id")
    private Long materialId;
}