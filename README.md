# TP2 Web — ALAMI LOUATI Ghali

Application de conversation Jakarta Faces et LangChain4j, réalisée pour la [partie Web du TP2](http://richard.grin.free.fr/emsi/casablanca-ia/tp/tp2-langchain4j/index.html#appliweb). Le nom du dossier et du dépôt reste `TP3Web-ALAMI_LOUATI_Ghali`, comme demandé.

## Prérequis

- JDK 25.
- Payara 7.2026.8 ou plus récent ; validation effectuée sur 7.2026.9.
- Une clé Gemini dans la variable d’environnement `GEMINI_KEY`, visible par le processus Payara. La clé ne doit figurer ni dans les fichiers du projet ni dans Git.
- Connexion Internet pour les dépendances Maven et les réponses Gemini.

Maven est fourni par `mvnw.cmd` et `mvnw`. Le modèle utilisé est `gemini-3.5-flash-lite`.

## Lancer l’application

Depuis un terminal PowerShell ouvert à la racine du projet :

```powershell
./scripts/Start-Web.ps1
```

Le script construit le WAR, démarre Payara si nécessaire, puis déploie l’application. Il utilise les installations présentes à côté du projet dans cet espace de travail. Pour utiliser d’autres installations :

```powershell
./scripts/Start-Web.ps1 -JavaHome 'C:/chemin/vers/jdk-25' -PayaraHome 'C:/chemin/vers/payara7'
```

Ouvrir ensuite [l’application locale](http://localhost:8080/TP3Web-ALAMI_LOUATI_Ghali/). L’URL du déploiement effectué par ce script démarre sur `index.xhtml` grâce à `WEB-INF/web.xml`.

Si `GEMINI_KEY` a été définie après le démarrage de Payara, redémarrer le serveur depuis un environnement qui contient cette variable.

### Depuis IntelliJ

1. Ouvrir `pom.xml` comme projet Maven et effectuer **Reload Maven Project**.
2. Choisir le JDK 25 pour le projet.
3. Ajouter une configuration **Payara Server > Local**, avec l’installation Payara 7.
4. Dans **Deployment**, ajouter l’artefact WAR de ce projet ; choisir `/TP3Web-ALAMI_LOUATI_Ghali` comme contexte.
5. Vérifier que Payara reçoit `GEMINI_KEY`, puis lancer la configuration.

## Fonctionnement

- `ht.ia2.alamilouati.ghali.jsf.Bb` : bean CDI `@Named`, `@ViewScoped` et `Serializable`. Il conserve question, réponse et historique pendant la vue.
- `ht.ia2.alamilouati.ghali.llm.LlmClient` : client CDI `@Dependent` qui utilise Gemini, une mémoire de 20 messages et le service IA `Assistant`.
- `Assistant.chat(String)` : interface implémentée par un proxy LangChain4j.
- Le rôle choisi est ajouté comme `SystemMessage` avant la première question. Il reste figé pendant la conversation.
- **Nouveau chat** ouvre une nouvelle vue, recrée les beans et permet de choisir un autre rôle.
- La sérialisation du client conserve les messages ; les objets techniques et la clé ne sont pas sérialisés.
- La page, la feuille de style et le JavaScript reprennent les [sources du TP0](http://richard.grin.free.fr/emsi/casablanca-ia/tp/tp0-jakartaee/correction/page.html), sans mode debug.

## Vérifier

Après lancement de Payara et déploiement :

```powershell
./scripts/Test-Web.ps1
```

Ce mode vérifie l’accueil JSF, les ressources et les validations du formulaire sans envoyer de question à Gemini.

Pour les contrôles avec le vrai modèle, qui consomment des tokens de l’API :

```powershell
./scripts/Test-Web.ps1 -WithGemini
```

La validation complète a réussi : **16 contrôles**, dont traduction de « bonjour », rôle personnalisé, mémoire entre deux échanges et remise à zéro après **Nouveau chat**. Les questions de test utilisent uniquement des données fictives.

La compilation seule s’effectue avec `./mvnw.cmd package` lorsque `JAVA_HOME` pointe vers le JDK 25.

## Périmètre et rendu

La partie obligatoire du TP2 Web est implémentée. Le comptage des tokens et le streaming WebSocket sont des exercices optionnels distincts.

Pour demander le bonus, l’énoncé prévoit un email au professeur contenant l’URL du dépôt, avec « TP 2 - Web terminé » dans le sujet. Aucun email n’est envoyé par les scripts du projet.
