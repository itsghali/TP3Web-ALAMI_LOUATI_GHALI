# AI Change Log

Journal des modifications réalisées avec l’assistant. Entrées conservées, plus récentes en premier.

## 2026-11-17 23:57 — Démarrage sur la page JSF

**Scope :** config
**Files :** `src/main/webapp/WEB-INF/web.xml` (modifié), `AI-CHANGELOG.md` (ajouté).
**What :** `index.xhtml` devient la page d’accueil grâce à `welcome-file-list`.
**Why :** appliquer l’étape « Quelques détails encore pour la partie Web » du TP2.
**Verified :** compilation Maven réussie ; déploiement sur Payara 7.2026.9 réussi ; racine de l’application en HTTP 200 avec formulaire JSF et choix du rôle.
**Revert :** retirer le bloc `welcome-file-list` de `web.xml`.
