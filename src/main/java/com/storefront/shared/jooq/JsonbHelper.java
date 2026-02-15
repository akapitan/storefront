package com.storefront.shared.jooq;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import org.jooq.JSONB;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.function.Function;
import java.util.function.Supplier;

final class JsonbHelper {

	private JsonbHelper() {
	}

	static JSONB serialize(Object value) {
		return JSONB.valueOf(apply(mapper -> mapper.writeValueAsString(value)));
	}

	static <T> T deserialize(JSONB jsonb, Class<T> type) {
		return apply(mapper -> mapper.readValue(jsonb.data(), type));
	}

	static <T> T deserialize(JSONB jsonb, TypeReference<T> typeReference) {
		return apply(mapper -> mapper.readValue(jsonb.data(), typeReference));
	}

	static <T> T deserialize(JSONB jsonb, TypeReference<T> typeReference, Supplier<T> fallback) {
		if (jsonb == null) {
			return fallback.get();
		}
		return deserialize(jsonb, typeReference);
	}


	private static final JsonMapper instance = JsonMapper.builder()
			.enable(MapperFeature.ACCEPT_CASE_INSENSITIVE_ENUMS)
			.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
			.disable(SerializationFeature.WRITE_DURATIONS_AS_TIMESTAMPS)
			.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
			.build();


	public static <T> T apply(JsonMapperFunction<T> action) {
		return action.apply(instance);
	}

	public static JsonMapper get() {
		return instance;
	}


	@FunctionalInterface
	public interface JsonMapperFunction<T> extends Function<JsonMapper, T> {

		T applyWithIoException(JsonMapper mapper) throws IOException;

		@Override
		default T apply(JsonMapper mapper) {
			try {
				return applyWithIoException(mapper);
			}
			catch (IOException ex) {
				throw new UncheckedIOException(ex);
			}
		}

	}

}
