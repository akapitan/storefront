@import com.storefront.catalog.CatalogApi.ProductGroupDetail
@import com.storefront.catalog.CatalogApi.ColumnConfig
@import com.storefront.catalog.CatalogApi.SkuRow
@import com.fasterxml.jackson.databind.ObjectMapper
@import java.util.List

@param ProductGroupDetail group
@param List<ColumnConfig> columns
@param List<SkuRow> skuRows

!{var mapper = new ObjectMapper();}

<table class="variant-table">
    <thead>
    <tr>
        <th class="vt-col-pn" style="width:120px">Part No.</th>
        @for(var col : columns)
            @if(!col.role().equals("filter_only"))
                <th class="vt-col" style="width:${col.widthPx()}px">
                    ${col.header()}
                    @if(col.unitLabel() != null)
                        <span class="vt-unit">(${col.unitLabel()})</span>
                    @endif
                </th>
            @endif
        @endfor
        <th class="vt-col-price" style="width:100px">Price</th>
        <th class="vt-col-stock" style="width:80px">Availability</th>
        <th class="vt-col-action" style="width:60px"></th>
    </tr>
    </thead>
    <tbody>
    @if(skuRows.isEmpty())
        <tr>
            <td colspan="${columns.size() + 3}" class="vt-empty">
                No items match your current filters.
            </td>
        </tr>
    @else
        @for(var sku : skuRows)
            !{
                    com.fasterxml.jackson.databind.JsonNode specs = null;
                    try { specs = mapper.readTree(sku.specsJson()); } catch (Exception e) {}
                }
            <tr class="vt-row ${sku.inStock() ? "" : "vt-row-oos"}">
                <td class="vt-cell-pn">
                    <span class="part-number">${sku.partNumber()}</span>
                </td>
                @for(var col : columns)
                    @if(!col.role().equals("filter_only"))
                        <td class="vt-cell">
                            @if(specs != null && specs.has(col.key()))
                                ${specs.get(col.key()).asText()}
                            @endif
                        </td>
                    @endif
                @endfor
                <td class="vt-cell-price">
                    @if(sku.price1ea() != null)
                        <span class="vt-price">${com.storefront.shared.web.TemplateHelpers.formatCurrency(sku.price1ea())}</span>
                        <span class="vt-sell-unit">/ ${sku.sellUnit()}</span>
                        @if(sku.priceTiersJson() != null)
                            <button class="vt-price-tiers-btn"
                                    title="Quantity pricing available"
                                    onclick="this.nextElementSibling.classList.toggle('visible')">qty
                            </button>
                            <div class="vt-price-tiers-popup">
                                !{
                                    java.util.List<com.fasterxml.jackson.databind.JsonNode> tierList = new java.util.ArrayList<>();
                                    try {
                                        var tiers = mapper.readTree(sku.priceTiersJson());
                                        if (tiers != null && tiers.isArray()) {
                                            for (var tier : tiers) {
                                                tierList.add(tier);
                                            }
                                        }
                                    } catch (Exception e) {}
                                }
                                @for(var tier : tierList)
                                    <div class="vt-tier">
                                        <span class="vt-tier-qty">${tier.get("qty_min").asInt()}+</span>
                                        <span class="vt-tier-price">$${tier.get("price").asText()}</span>
                                    </div>
                                @endfor
                            </div>
                        @endif
                    @endif
                </td>
                <td class="vt-cell-stock">
                    @if(sku.inStock())
                        <span class="stock-badge in-stock">In Stock</span>
                    @else
                        <span class="stock-badge out-of-stock">Out of Stock</span>
                    @endif
                </td>
                <td class="vt-cell-action">
                    @if(sku.inStock())
                        <form hx-post="/cart/add"
                              hx-target="#cart-badge"
                              hx-swap="outerHTML">
                            <input type="hidden" name="skuId" value="${String.valueOf(sku.id())}"/>
                            <input type="hidden" name="qty" value="1"/>
                            <button type="submit" class="vt-add-btn" title="Add to cart">+</button>
                        </form>
                    @endif
                </td>
            </tr>
        @endfor
    @endif
    </tbody>
</table>
