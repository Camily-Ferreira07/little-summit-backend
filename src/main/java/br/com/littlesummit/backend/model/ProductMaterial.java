package br.com.littlesummit.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Representa a quantidade de cada material necessária para produzir uma unidade de um produto.
 */
@Entity
@Table(name = "product_materials")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductMaterial {

    @EmbeddedId
    @Builder.Default
    private ProductMaterialId id = new ProductMaterialId();

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("productId")
    @JoinColumn(name = "product_id")
    private Product product;

    @ManyToOne(fetch = FetchType.EAGER)
    @MapsId("materialId")
    @JoinColumn(name = "material_id")
    private Material material;

    @Column(name = "quantity_per_unit", nullable = false, precision = 10, scale = 2)
    private BigDecimal quantityPerUnit;
}