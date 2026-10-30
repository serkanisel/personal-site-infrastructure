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

# GitHub Repository Adresleri (SSH formatı - server SSH key'ini kullanır)
BACKEND_REPO="${BACKEND_REPO:-git@github.com:serkanisel/personal-site-backend.git}"
FRONTEND_REPO="${FRONTEND_REPO:-git@github.com:serkanisel/personal-site-frontend.git}"
BRANCH="${BRANCH:-main}"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}      Serkan İşel - Kişisel Blog Deployment Script    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Scriptin bulunduğu dizini ve ana çalışma kökünü tespit et
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    # Script personal-site-infrastructure içinde çalıştırıldı
    COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
    ENV_DIR="$SCRIPT_DIR"
    PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -f "$SCRIPT_DIR/personal-site-infrastructure/docker-compose.yml" ]; then
    # Script ana proje klasöründe çalıştırıldı
    COMPOSE_FILE="$SCRIPT_DIR/personal-site-infrastructure/docker-compose.yml"
    ENV_DIR="$SCRIPT_DIR/personal-site-infrastructure"
    PARENT_DIR="$SCRIPT_DIR"
else
    echo -e "${RED}[HATA] docker-compose.yml dosyası bulunamadı!${NC}"
    exit 1
fi

# 1. Docker & Docker Compose Kontrolü
echo -e "\n${YELLOW}[1/6] Docker ve Docker Compose kontrol ediliyor...${NC}"
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

# 2. Git Kontrolü
echo -e "\n${YELLOW}[2/6] Git kontrol ediliyor...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}[!] Git bulunamadı! Lütfen git yükleyin (örn: apt install -y git).${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git hazır.${NC}"

# 3. Backend ve Frontend Repolarını GitHub'dan Çekme / Güncelleme
echo -e "\n${YELLOW}[3/6] Backend ve Frontend kaynak kodları senkronize ediliyor...${NC}"

# 3.1 Backend Repo
BACKEND_DIR="$PARENT_DIR/personal-site-backend"
if [ -d "$BACKEND_DIR/.git" ]; then
    echo -e "${BLUE}→ Backend klasörü mevcut, en son kodlar çekiliyor (git pull)...${NC}"
    git -C "$BACKEND_DIR" remote set-url origin "$BACKEND_REPO" 2>/dev/null || true
    git -C "$BACKEND_DIR" fetch origin "$BRANCH"
    git -C "$BACKEND_DIR" checkout "$BRANCH"
    git -C "$BACKEND_DIR" pull origin "$BRANCH"
    echo -e "${GREEN}✓ Backend güncellendi.${NC}"
elif [ -d "$BACKEND_DIR" ]; then
    echo -e "${YELLOW}[i] Backend klasörü mevcut (git repo değil), mevcut kodlar kullanılacak.${NC}"
else
    echo -e "${BLUE}→ Backend klasörü bulunamadı, GitHub'dan SSH ile klonlanıyor...${NC}"
    git clone -b "$BRANCH" "$BACKEND_REPO" "$BACKEND_DIR"
    echo -e "${GREEN}✓ Backend başarıyla klonlandı.${NC}"
fi

# 3.2 Frontend Repo
FRONTEND_DIR="$PARENT_DIR/personal-site-frontend"
if [ -d "$FRONTEND_DIR/.git" ]; then
    echo -e "${BLUE}→ Frontend klasörü mevcut, en son kodlar çekiliyor (git pull)...${NC}"
    git -C "$FRONTEND_DIR" remote set-url origin "$FRONTEND_REPO" 2>/dev/null || true
    git -C "$FRONTEND_DIR" fetch origin "$BRANCH"
    git -C "$FRONTEND_DIR" checkout "$BRANCH"
    git -C "$FRONTEND_DIR" pull origin "$BRANCH"
    echo -e "${GREEN}✓ Frontend güncellendi.${NC}"
elif [ -d "$FRONTEND_DIR" ]; then
    echo -e "${YELLOW}[i] Frontend klasörü mevcut (git repo değil), mevcut kodlar kullanılacak.${NC}"
else
    echo -e "${BLUE}→ Frontend klasörü bulunamadı, GitHub'dan SSH ile klonlanıyor...${NC}"
    git clone -b "$BRANCH" "$FRONTEND_REPO" "$FRONTEND_DIR"
    echo -e "${GREEN}✓ Frontend başarıyla klonlandı.${NC}"
fi

# 4. .env Dosyası Kontrolü
echo -e "\n${YELLOW}[4/6] Çevre değişkenleri (.env) kontrol ediliyor...${NC}"
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

# 5. İmajları Derleme ve Başlatma
echo -e "\n${YELLOW}[5/6] Docker imajları derleniyor ve servisler ayağa kaldırılıyor...${NC}"
docker compose -f "$COMPOSE_FILE" up -d --build

# 6. Gereksiz Eski İmajları Temizleme ve Durum Kontrolü
echo -e "\n${YELLOW}[6/6] Kullanılmayan eski Docker imajları temizleniyor...${NC}"
docker image prune -f > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Temizlik tamamlandı.${NC}"

sleep 3
docker compose -f "$COMPOSE_FILE" ps

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}  ✓ KURULUM BAŞARIYLA TAMAMLANDI!                    ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Web siteniz yayında:"
echo -e "  🌐 Frontend:  http://127.0.0.1:8081 (Nginx üzerinden: https://serkanisel.com.tr)"
echo -e "  ⚙️  Admin:     https://serkanisel.com.tr/admin/login"
echo -e "  🔌 API (İç):  http://127.0.0.1:8080 (Yalnızca sunucu içi)"
echo -e "  🐘 Postgres:  127.0.0.1:5432 (Yalnızca sunucu içi)"
echo -e "\nLogları canlı izlemek için:"
echo -e "  docker compose -f $COMPOSE_FILE logs -f"
echo -e "${GREEN}======================================================${NC}"
