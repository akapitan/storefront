package com.storefront.shared.jooq;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jooq.Converter;
import org.jooq.exception.DataTypeException;

/**
 * JsonNodeConverter — maps PostgreSQL JSONB ↔ Jackson JsonNode.
 * ═══════════════════════════════════════════════════════════════
 *
 * Referenced in build.gradle.kts jOOQ codegen config so that all
 * JSONB columns are automatically typed as JsonNode in generated records.
 *
 * Used by product.attributes, product.metadata, and any future JSONB columns.
 */
public class JsonNodeConverter implements Converter<Object, JsonNode> {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Override
    public JsonNode from(Object dbObject) {
        if (dbObject == null) return MAPPER.nullNode();
        try {
            String json = dbObject.toString();
            return MAPPER.readTree(json);
        } catch (Exception e) {
            throw new DataTypeException("Failed to convert JSONB to JsonNode: " + dbObject, e);
        }
    }

    @Override
    public Object to(JsonNode userObject) {
        if (userObject == null || userObject.isNull()) return null;
        try {
            return MAPPER.writeValueAsString(userObject);
        } catch (Exception e) {
            throw new DataTypeException("Failed to convert JsonNode to JSONB string", e);
        }
    }

    @Override
    public Class<Object> fromType() {
        return Object.class;
    }

    @Override
    public Class<JsonNode> toType() {
        return JsonNode.class;
    }
}
