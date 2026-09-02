# Rotar entre modo rápido y modo profundo

No hay un interruptor físico en Cursor: **cada mensaje** (o el inicio de una tarea) indica el modo. El agente lee frases clave y el tipo de trabajo.

## Modos en una línea

| Modo | Perfil harness | Cuándo |
|------|----------------|--------|
| **Rápido** | `composer-fast` | Default — Q&A, edits chicos, Composer Fast |
| **Equilibrado** | `coding-default`, `design-ui`, etc. | Trabajo normal por dominio |
| **Profundo** | `security-max`, `research-deep`, `agentic-long` | Auditoría, research, agente largo |
| **Stack completo** | `full-spectrum` | Multi-dominio, máximo provecho |

Capacidades (L2, subagents, GRM, `.k3/`) **no se borran** — se activan al escalar.

---

## 1. Frases en el chat (lo más simple)

### Volver a rápido

Escribe al inicio del mensaje (o solo):

- `rápido` / `modo rápido`
- `velocidad` / `respuesta rápida`
- `composer fast` / `sin rodeos`
- `optimiza velocidad`

→ Perfil **`composer-fast`**: sin subagents, sin L2, sin `.k3/`, effort **low**.

### Abrir stack completo (full-spectrum)

- `full-spectrum` / `modo full-spectrum`
- `máximo provecho` / `libertad total`
- `usa todo el stack` / `sin restricciones de dominio`

→ Perfil **`full-spectrum`**: Top-k hasta **16**, subagents, L2 on-demand, effort **max**.

### Profundo pero acotado (sin mega-catálogo)

Di el **dominio** en lenguaje natural:

- Seguridad / auditoría → `security-max` (effort max, Semgrep, security-auditor…)
- Research profundo → `research-deep`
- Feature grande / código → `coding-default` o pide **SPARC**
- Agente largo / browser → `agentic-long`

Ejemplo: *「modo security-max: revisa auth de esta API」*

---

## 2. Bloque explícito (máxima claridad)

Copia al inicio del mensaje cuando quieras fijar el modo:

**Rápido:**

```yaml
mode: composer-fast
effort: low
harness_profile: composer-fast
```

**Full-spectrum:**

```yaml
mode: full-spectrum
effort: max
harness_profile: full-spectrum
```

**Coding serio:**

```yaml
mode: efficient
effort: high
harness_profile: coding-default
```

---

## 3. Escalada automática (sin que digas nada)

El agente **sube** de `composer-fast` si detecta, por ejemplo:

- Muchos archivos + tests + review
- Auditoría, incidente, compliance
- Pides explícitamente orchestration, subagents o `effort: max`

**Baja** otra vez si en el **siguiente** mensaje usas frases rápidas o una pregunta simple.

---

## 4. Invocar el router como Task

Para sesiones largas con cambio claro de postura:

- Task / subagent: **`k3-cognitive-router`**
- En la descripción: `modo full-spectrum` o `modo composer-fast`

El agente principal puede seguir en Fast; el router lleva RAOVA y expertos.

---

## 5. Modelo de Cursor

- **Composer 2.5 Fast** + sin frases de profundidad → encaja con **composer-fast** (default).
- Para trabajo pesado puedes seguir en Fast y decir `full-spectrum`, o cambiar a un modelo “thinking” **y** decir `effort: max` — el harness no sustituye al modelo, pero alinea el comportamiento.

---

## 6. Cheat sheet de una línea

| Quiero… | Escribe… |
|---------|----------|
| Respuesta ya | `rápido:` + tu pregunta |
| Todo el ecosistema | `usa todo el stack:` + tarea |
| Solo seguridad fuerte | `security-max:` + alcance |
| Buscar skill marketplace | `busca en L2:` + keyword (solo en modos con L2) |
| Volver a lo mínimo tras algo grande | Nuevo mensaje: `modo rápido, solo:` + lo siguiente |

---

## Persistencia entre turnos

- **No** hay un flag global guardado en Cursor por defecto.
- Estado opcional en `.k3/orchestrator-state.json` solo en trabajo **max** / largo (modo profundo).
- Para “quedarme en full-spectrum toda la conversación”, repite la frase cada 3–4 turnos o abre un chat dedicado con `full-spectrum` en el primer mensaje.
