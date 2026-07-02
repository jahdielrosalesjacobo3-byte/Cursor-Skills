# Perfiles de skills (~1594 en disco)

Solo **un subconjunto** está activo a la vez. El catálogo completo antigravity (~1416 skills) **no** convive con los bundles.

## Reglas anti-colisión

| Regla | Efecto |
|-------|--------|
| **Catálogo XOR bundles** | Si `antigravity-awesome-skills` está ON → todos los bundles OFF |
| **Catálogo solo en `mega`** | Cualquier otro perfil → catálogo OFF |
| **ruflo-core OFF** | En todos los perfiles salvo `mega` + `ALLOW_RUFLO_CORE=1` (evita hooks en Cursor) |

Se aplican al ejecutar: `claude-profile use <perfil>`

## Presupuesto de skills por perfil (aprox.)

| Perfil | Plugins | Skills ~activas |
|--------|--------:|----------------:|
| baseline | 3 | 16 |
| coder | 10 | 45 |
| autonomous | 15 | 52 |
| web | 8 | 48 |
| security | 9 | 42 |
| research | 11 | 55 |
| devops | 12 | 50 |
| trading | 6 | 25 |
| iot | 10 | 40 |
| **mega** | 38 | **~1500** |

## Modos `ccode` y skills

Los modos **no cargan skills extra**; solo cambian permisos y a veces el perfil:

- `cc-plan` / `cc-smart` / `cc-yolo` → mismo perfil, distintos flags Claude
- `cc-fly` / `cc-max` → fuerzan perfil **autonomous** (~52 skills)
- `cc-mega` → usa perfil **mega** (catálogo completo)

## Validar

```bash
claude-profile validate
claude-profile audit-skills
```
