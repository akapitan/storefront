---
name: storefront-presentation
description: Use when creating or modifying controllers, request/response DTOs, JTE templates, or HTMX interactions. Handles the interfaces layer of the hexagonal architecture.
argument-hint: "[module-name or view-name]"
context: fork
agent: general-purpose
---

# Presentation — Controllers + DTOs + JTE Templates

Creates the interfaces layer: REST controllers with HTMX support, request/response DTOs, and JTE templates.

## Controller

```java
// Location: com.storefront.<module>.interfaces
// Visibility: package-private
@Controller
@RequestMapping("/<module>")
@RequiredArgsConstructor
class OrderController {

    private final OrderApi orderApi;

    @GetMapping("/{id}")
    public String show(@PathVariable UUID id, HttpServletRequest request, Model model) {
        var order = orderApi.findById(new OrderId(id))
                .orElseThrow(() -> new OrderNotFoundException(new OrderId(id)));

        model.addAttribute("order", order);

        if (HtmxResponse.isHtmxRequest(request)) {
            return "<module>/order-detail-content";   // HTMX fragment
        }
        return "<module>/order-detail-page";           // full page with layout
    }

    @GetMapping
    public String list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request,
            HttpServletResponse response,
            Model model) {

        var slice = orderApi.findByCustomer(
                getCurrentCustomerId(),
                SliceRequest.of(page, size));

        model.addAttribute("orders", slice);
        HtmxResponse.pushUrl(response, buildUrl(page, size));

        if (HtmxResponse.isHtmxRequest(request)) {
            return "<module>/order-list-content";
        }
        return "<module>/order-list-page";
    }
}
```

**Controller rules:**
- Package-private class, `@Controller`
- Injects the module's **public API interface** (NOT the service class directly)
- Returns JTE template name as string
- HTMX detection: `HtmxResponse.isHtmxRequest(request)` → fragment, else full page
- Use `HtmxResponse.pushUrl(response, url)` for browser URL updates
- Use `HtmxResponse.trigger(response, event)` for client-side events
- Never expose domain entities to templates — use API projection records

## HTMX Patterns

**Fragment vs full page:**
```java
if (HtmxResponse.isHtmxRequest(request)) {
    return "module/view-content";   // fragment only (no layout wrapper)
}
return "module/view-page";          // full page with layout
```

**Infinite scroll (Slice pagination):**
```html
<div hx-get="/orders?page=${slice.page() + 1}"
     hx-trigger="revealed"
     hx-swap="afterend">
</div>
```

**Debounced search:**
```html
<input type="search"
       hx-get="/orders/search"
       hx-trigger="input changed delay:300ms"
       hx-target="#results"
       name="q">
```

## Request/Response DTOs

```java
// Location: com.storefront.<module>.interfaces
// Only needed when API projection records don't match what the template needs
record OrderListItem(UUID id, String status, String formattedDate) {
    static OrderListItem from(OrderApi.OrderSummary summary) {
        return new OrderListItem(
            summary.id().value(),
            summary.status().displayName(),
            DateFormatter.format(summary.createdAt())
        );
    }
}
```

**DTO rules:**
- Only create DTOs when API projection records don't match template needs
- Live in `interfaces/` package
- Package-private records
- Static factory method `from(ApiProjection)` for mapping

## JTE Templates

**Directory structure:**
```
src/main/resources/templates/jte/<module>/
├── order-detail-page.jte          # Full page (includes layout)
├── order-detail-content.jte       # HTMX fragment
├── order-list-page.jte            # Full page
└── order-list-content.jte         # HTMX fragment
```

**Naming convention:** `<entity>-<view>-page.jte` for full pages, `<entity>-<view>-content.jte` for fragments.

**Full page template pattern:**
```html
@import com.storefront.<module>.OrderApi.OrderDetail
@param OrderDetail order

@template.layout(title = "Order Details")
    <div id="order-content">
        <%-- Content here --%>
    </div>
@endtemplate
```

**Fragment template pattern:**
```html
@import com.storefront.<module>.OrderApi.OrderDetail
@param OrderDetail order

<div id="order-content">
    <%-- Same content as page, without layout wrapper --%>
</div>
```

## Testing

```java
class OrderControllerTest extends BaseIntegrationTest {
    @Autowired MockMvc mockMvc;

    @Test
    void showReturnsFullPage() throws Exception {
        mockMvc.perform(get("/orders/" + existingOrderId))
                .andExpect(status().isOk())
                .andExpect(view().name("orders/order-detail-page"));
    }

    @Test
    void showReturnsFragmentForHtmx() throws Exception {
        mockMvc.perform(get("/orders/" + existingOrderId)
                        .header("HX-Request", "true"))
                .andExpect(status().isOk())
                .andExpect(view().name("orders/order-detail-content"));
    }

    @Test
    void listReturnsPaginatedResults() throws Exception {
        mockMvc.perform(get("/orders?page=0&size=10"))
                .andExpect(status().isOk())
                .andExpect(model().attributeExists("orders"));
    }
}
```

**Test rules:**
- Extend `BaseIntegrationTest` for MockMvc tests
- Test BOTH full-page and HTMX fragment responses
- Test pagination parameters
- Test 404 for missing resources
