#!/bin/bash

# ========================================
# Script para criar release automaticamente
# ========================================
# Uso: bash scripts/release.sh 1.2.0
# Aceita sufixos: bash scripts/release.sh 1.2.0-test

# Definir raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Mudar para a raiz do projeto
cd "$PROJECT_ROOT" || exit 1

# Validação de argumentos
if [[ -z "$1" ]]; then
    echo "Uso: bash scripts/release.sh <versao>"
    echo "Exemplo: bash scripts/release.sh 1.2.0"
    echo "Com sufixo: bash scripts/release.sh 1.2.0-test"
    exit 1
fi

NEW_VERSION="$1"

# Validar formato da versão (X.Y.Z ou X.Y.Z-sufixo)
if ! echo "$NEW_VERSION" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"; then
    echo "Erro: Versão deve estar no formato X.Y.Z ou X.Y.Z-sufixo (ex: 1.2.0, 1.2.0-test)"
    exit 1
fi

echo
echo "========================================"
echo " Criando Release v$NEW_VERSION"
echo "========================================"
echo

# [1/6] Atualizar pubspec.yaml
echo "[1/6] Atualizando pubspec.yaml..."
if ! sed -i "s/^version: .*/version: $NEW_VERSION/" "$PROJECT_ROOT/pubspec.yaml"; then
    echo "Erro ao atualizar pubspec.yaml"
    exit 1
fi

# [2/6] Adicionar ao Git
echo "[2/6] Adicionando mudanças ao Git..."
if ! git add "$PROJECT_ROOT/pubspec.yaml"; then
    echo "Erro ao adicionar ao Git"
    exit 1
fi

# [3/6] Commit
echo "[3/6] Criando commit..."
if ! git commit -m "chore: bump version to $NEW_VERSION"; then
    echo "Erro ao criar commit"
    exit 1
fi

# [4/6] Solicitar notas de release
echo
echo "[4/6] Digite as notas de release (uma por linha, linha vazia para finalizar):"
echo

NOTES=""
LINE_COUNT=0

while true; do
    read -p "- " LINE
    if [[ -z "$LINE" ]]; then
        break
    fi
    NOTES="${NOTES}- ${LINE}\n"
    ((LINE_COUNT++))
done

if [[ $LINE_COUNT -eq 0 ]]; then
    NOTES="- Atualização de manutenção"
fi

# [5/6] Criar tag anotada
echo
echo "[5/6] Criando tag anotada v$NEW_VERSION..."

# Criar arquivo temporário com a mensagem da tag
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
Release $NEW_VERSION

### Novidades

$(echo -e "$NOTES")
EOF

if ! git tag -a "v$NEW_VERSION" -F "$TEMP_FILE"; then
    echo "Erro ao criar tag"
    rm "$TEMP_FILE"
    exit 1
fi
rm "$TEMP_FILE"

# [6/6] Push para branch atual
CURRENT_BRANCH=$(git branch --show-current)
echo "[6/6] Fazendo push do commit e da tag para $CURRENT_BRANCH..."

if ! git push origin "$CURRENT_BRANCH"; then
    echo "Erro ao fazer push do commit"
    exit 1
fi

if ! git push origin "v$NEW_VERSION"; then
    echo "Erro ao fazer push da tag"
    exit 1
fi

echo
echo "========================================"
echo " Release v$NEW_VERSION criado com sucesso!"
echo "========================================"
echo

# Detectar URL do GitHub automaticamente
GITHUB_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's/^git@github\.com:/https:\/\/github.com\//')

echo "O GitHub Actions vai iniciar o build automaticamente."
echo "Acompanhe em: $GITHUB_URL/actions"
echo
