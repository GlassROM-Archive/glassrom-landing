# This script just updates bromite
cd external/chromium-webview/prebuilt
archs=(
	arm
	arm64
	x86
)
VERSION="85.0.4183.84"
KEY="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBFphnJwBCAC1qSMaPR5Nq9sEHa9ZePwoGLFafjOBcApz7IYW7dIsQYXVUHlo
lbBwwfFUjnnIf/wzZ42ck/QGRKJ18qA9VybWyT8as0Sz26Tmxah31vI7kzlBZCYY
/ZER5N3onQFVVVoynYxmep5HdK7enAXOtLBOogbJ/x2Q9ITPuJ+Pv3b4R5E2ui/i
hFAruUh+oifPBzh3fjBTTr0uvDqbsnsczQptFghKxYyJiPTblCD51Ou11a3uNt1y
PuG1bR5jImgt33T6zjdFac6kQ2Zalxa/URU/FQPiYJ1X2J1jCgdEgRKlK70ha+oN
mnVWhFzjecuCw180HCZh1OQho+LPWbtMFyvtABEBAAG0M2NzYWdhbjUgPDMyNjg1
Njk2K2NzYWdhbjVAdXNlcnMubm9yZXBseS5naXRodWIuY29tPokBIgQTAQgAFgUC
WmGcnAkQZBkKUdhdwMUCGwsCGQEAADpDB/4zlnDg1gToKqtz994jLzUM7PJOPTWa
c8xGCj7l8BpGcCOK0fk7fOQ+bDYT0OSHZ1OCR7Gbm6ENu03wNLQ7W9Tr0uf/yDIP
mItcFk6nYmMKPnK6bd7QWLMsT9mK6mYb02zt6Ql8D7EsWGxifQVQG85ETObhoSqw
EH6zqZvflxJLmN+vh/Orm1ipzEvw7cjvpSloDwypjY6x9MGEE9utFcGySx726gKu
Wmz417QZc/TpylCd1p72G9pCqv1Si+y+P9tSEdjWSM6EqEwMr5W+IJ1O6BZQ7A9p
0l2FZqYC2WkRDJZqWiYoYltP6z1SEbbVI5rQaaVAesS1Ae8OOR9EmlK8
=6Hsd
-----END PGP PUBLIC KEY BLOCK-----"
verify=(
	txt.asc
	txt
)
for i in ${verify[@]}; do
	wget https://github.com/bromite/bromite/releases/download/"$VERSION"/brm_$VERSION.sha256."$i"
done
echo "$KEY" >csagan5.asc
gpg2 --import csagan5.asc
gpg2 --verify brm_"$VERSION".sha256.txt.asc

for i in ${archs[@]}; do
	sha256=$(cat brm_"$VERSION".sha256.txt | grep "$i"_SystemWebView.apk | awk '{ print $1}')
	cd "$i"
	curl -fsSL https://github.com/bromite/bromite/releases/download/"$VERSION"/"$i"_SystemWebView.apk >webview.apk
	sha256_check=$(sha256sum webview.apk | awk '{print $1}')
	if [ "$sha256" != "$sha256_check" ]; then
		echo "Error at $i. Expected $sha256 but have $sha256_check"
		exit 1
	fi
	cd ..
done
