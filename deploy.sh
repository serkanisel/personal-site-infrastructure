#!/usr/bin/env bash

# ==============================================================================
# Serkan İşel Kişisel Web Sitesi - Otomatik Deployment & Kurulum Scripti
# ==============================================================================

set -e

# Renkler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}      Serkan İşel - Kişisel Blog Deployment Script    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Scriptin bulunduğu dizini tespit et
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Compose dosyasının yerini belirle
if [ -f "$SCRIPT_DIR/personal-site-infrastructure/docker-compose.yml" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/personal-site-infrastructure/docker-compose.yml"
    ENV_DIR="$SCRIPT_DIR/personal-site-infrastructure"
elif [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
    ENV_DIR="$SCRIPT_DIR"
else
    echo -e "${RED}[HATA] docker-compose.yml dosyası bulunamadı!${NC}"
    exit 1
fi

# 1. Docker Kontrolü
echo -e "\n${YELLOW}[1/5] Docker ve Docker Compose kontrol ediliyor...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[!] Docker bulunamadı! Lütfen sunucunuza Docker kurun:${NC}"
    echo "    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}[!] Docker Compose plugin bulunamadı!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker ve Docker Compose hazır.${NC}"

# 2. .env Dosyası Kontrolü
echo -e "\n${YELLOW}[2/5] Çevre değişkenleri (.env) kontrol ediliyor...${NC}"
if [ ! -f "$ENV_DIR/.env" ]; then
    if [ -f "$ENV_DIR/.env.example" ]; then
        echo -e "${YELLOW}[i] .env dosyası bulunamadı, .env.example kopyalanıyor...${NC}"
        cp "$ENV_DIR/.env.example" "$ENV_DIR/.env"
        echo -e "${GREEN}✓ $ENV_DIR/.env oluşturuldu.${NC}"
        echo -e "${YELLOW}Not: Şifreleri ve portları değiştirmek isterseniz $ENV_DIR/.env dosyasını düzenleyebilirsiniz.${NC}"
    fi
else
    echo -e "${GREEN}✓ .env dosyası mevcut.${NC}"
fi

# 3. İmajları Derleme ve Başlatma
echo -e "\n${YELLOW}[3/5] Docker imajları derleniyor ve servisler ayağa kaldırılıyor...${NC}"
docker compose -f "$COMPOSE_FILE" up -d --build

# 4. Gereksiz Eski İmajları Temizleme
echo -e "\n${YELLOW}[4/5] Kullanılmayan eski Docker imajları temizleniyor...${NC}"
docker image prune -f > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Temizlik tamamlandı.${NC}"

# 5. Servis Durumunu Kontrol Etme
echo -e "\n${YELLOW}[5/5] Servis durumları kontrol ediliyor...${NC}"
sleep 3
docker compose -f "$COMPOSE_FILE" ps

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}  ✓ KURULUM BAŞARIYLA TAMAMLANDI!                    ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Web siteniz yayında:"
echo -e "  🌐 Frontend:  http://<SUNUCU_IP_ADRESI>/"
echo -e "  ⚙️  Admin:     http://<SUNUCU_IP_ADRESI>/admin/login"
echo -e "  🔌 API (İç):  http://127.0.0.1:8080 (Yalnızca sunucu içi)"
echo -e "  🐘 Postgres:  127.0.0.1:5432 (Yalnızca sunucu içi)"
echo -e "\nLogları canlı izlemek için:"
echo -e "  docker compose -f $COMPOSE_FILE logs -f"
echo -e "${GREEN}======================================================${NC}"
