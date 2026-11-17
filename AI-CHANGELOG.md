# AI Change Log

Journal des modifications réalisées avec l’assistant. Entrées conservées, plus récentes en premier.

## 2026-11-18 00:34 — Comptage des tokens pour toute la session

**Scope :** feature et test
**Files :** `llm/CompteurTokens.java` (ajouté), `llm/Assistant.java`, `llm/LlmClient.java`, `jsf/Bb.java`, `index.xhtml`, `scripts/Test-Web.ps1`, `README.md` et ce journal (modifiés ; classes sous `src/main/java/ht/ia2/alamilouati/ghali`, page sous `src/main/webapp`).
**What :** `Assistant` retourne `Result<String>` ; le client ajoute l’usage du modèle à un accumulateur CDI `@SessionScoped`. Le backing bean expose le total en lecture seule dans la page JSF.
**Why :** réaliser la première option du TP2 sans perdre le cumul lors d’un changement de vue ou de rôle.
**Verified :** build et déploiement réussis ; 24 contrôles HTTP passent avec Gemini réel, dont conservation du total après nouveau chat, croissance après changement de rôle et isolation entre sessions.
**Revert :** rétablir le retour `String`, retirer l’accumulation, l’affichage et `CompteurTokens` ; conserver les entrées du journal.

## 2026-11-18 00:00 — Validation complète du TP2 Web

**Scope :** test et documentation
**Files :** `scripts/Start-Web.ps1` (ajouté), `scripts/Test-Web.ps1` (ajouté), `README.md` (ajouté), `AI-CHANGELOG.md` (complété).
**What :** ajout d’un lancement reproductible Maven/Payara, d’un contrôle HTTP du formulaire JSF et d’un guide de lancement IntelliJ. Le mode `-WithGemini` vérifie aussi la traduction, le rôle personnalisé, la mémoire et le nouveau chat.
**Why :** terminer la partie obligatoire du TP2 Web et rendre ses vérifications reproductibles.
**Verified :** 16 contrôles réussis sur Payara 7.2026.9 avec Gemini réel ; lancement et 8 contrôles sans appel Gemini réussis aussi sous Windows PowerShell 5.1 ; modèle `gemini-3.5-flash-lite` confirmé par la liste des modèles de l’API. Aucun secret enregistré, `IA.md` inchangé.
**Revert :** retirer les deux scripts et le README ; le code du chat reste celui du commit « Backing bean ».

## 2026-11-17 23:57 — Démarrage sur la page JSF

**Scope :** config
**Files :** `src/main/webapp/WEB-INF/web.xml` (modifié), `AI-CHANGELOG.md` (ajouté).
**What :** `index.xhtml` devient la page d’accueil grâce à `welcome-file-list`.
**Why :** appliquer l’étape « Quelques détails encore pour la partie Web » du TP2.
**Verified :** compilation Maven réussie ; déploiement sur Payara 7.2026.9 réussi ; racine de l’application en HTTP 200 avec formulaire JSF et choix du rôle.
**Revert :** retirer le bloc `welcome-file-list` de `web.xml`.
