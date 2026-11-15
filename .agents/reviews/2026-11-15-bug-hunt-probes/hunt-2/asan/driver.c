#include "zuid_formats.h"
#include "zuid_enc.h"
#include "zuid_sqids.h"
#include "zuid_cid.h"
#include "zuid_tables.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);
static uint64_t st = 88172645463325252ULL;
static uint32_t rnd(void){ st ^= st<<13; st ^= st>>7; st ^= st<<17; return (uint32_t)(st>>16); }
static void feed(unsigned sel, const uint8_t *b, size_t n){
    uint8_t *buf = malloc(n+1); buf[0]=(uint8_t)sel; memcpy(buf+1,b,n);
    LLVMFuzzerTestOneInput(buf,n+1); free(buf);
}
static const char *alpha[] = {
 "0123456789abcdefABCDEF-", "0123456789ABCDEFGHJKMNPQRSTVWXYZabcdefghjkmnpqrstvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=abcdefghijklmnopqrstuvwxyz",
 "0123456789ABCDEFGHIJKLMNOPQRSTUV=abcdefghijklmnopqrstuv", "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
 "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz", "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
 "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=",
 "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz", "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
 "bdfghjklmnprstvzaiou-BDFG", "abcdefghijklmnopqrstuvwxyz -AZ"};
static size_t lens[400]; static int nl;
int main(void){
    for (size_t i=0;i<=80;i++) lens[nl++]=i;
    size_t around[] = {128,256,384,512,768,1024,2048,4096};
    for (int a=0;a<8;a++) for (int d=-6; d<=6; d++) lens[nl++]=around[a]+d;
    lens[nl++]=65535; lens[nl++]=65536; lens[nl++]=65537; lens[nl++]=89478; lens[nl++]=131072;
    long calls=0;
    /* decoders: every form */
    for (int f=0; f<ZUID_ENC_N; f++) for (int li=0; li<nl; li++) {
        size_t len=lens[li]; uint8_t *b=malloc(len?len:1); size_t al=strlen(alpha[f]);
        for (int cls=0; cls<8; cls++) {
            if (len>5000 && cls>2) continue;
            for (size_t i=0;i<len;i++) switch(cls){
                case 0: b[i]=(uint8_t)alpha[f][rnd()%al]; break;
                case 1: b[i]=(uint8_t)alpha[f][0]; break;
                case 2: b[i]=(uint8_t)alpha[f][f==5?57:(f==0?15:(al>31?31:al-1))]; break;
                case 3: b[i]=(uint8_t)rnd(); break;
                case 4: b[i]=(uint8_t)(i%2? alpha[f][0] : alpha[f][rnd()%al]); break;
                case 5: b[i]=(uint8_t)(i<len/2? alpha[f][0] : alpha[f][rnd()%al]); break;
                case 6: b[i]=(uint8_t)(i==0? alpha[f][rnd()%4] : alpha[f][rnd()%al]); break;
                default: b[i]=(uint8_t)(i%6==5? '-' : alpha[f][rnd()%al]); break;
            }
            feed(0x40+f,b,len); calls++;
            /* with width */
            uint8_t *out=malloc(zuid_dec_max_len(len));
            long n=zuid_decode(f,(char*)b,len,NULL,-1,out);
            long ws[]={0,1,n-1,n,n+1,16,65536};
            for (int w=0;w<7;w++){ if(ws[w]<0) continue; if (len>5000 && w!=3 && w!=6) continue; uint8_t *o2=malloc(zuid_dec_max_len(len)); long m=zuid_decode(f,(char*)b,len,NULL,ws[w],o2);
                if (n>=0 && ws[w]==n) { if (m!=n || memcmp(o2,out,(size_t)n)) { printf("WIDTH mismatch form %d len %zu\n",f,len); } }
                else if (m>=0 && !(n>=0 && ws[w]==n)) printf("WIDTH accepted wrong form %d len %zu w %ld n %ld m %ld\n",f,len,ws[w],n,m);
                free(o2);} free(out);
            /* encoders on same bytes */
            if (cls==3 && len<=4096) { feed(0x60+f,b,len); calls++; }
        }
        free(b);
    }
    printf("decoders done %ld\n",calls); fflush(stdout);
    /* valid encodings at big sizes: encode -> decode */
    size_t big[]={255,256,257,65535,65536};
    for (int f=0; f<ZUID_ENC_N; f++) for (int k=0;k<5;k++) for (int cls=0; cls<3; cls++){
        size_t n=big[k]; if ((f==ZUID_ENC_PROQUINT||f==ZUID_ENC_WORDS) && n%2) n++;
        uint8_t *b=malloc(n); for(size_t i=0;i<n;i++) b[i]= cls==0?(uint8_t)rnd(): cls==1?0:0xff;
        char *t=malloc(zuid_enc_max_len(f,n,NULL,1)+1); long m=zuid_encode(f,b,n,NULL,"-",1,t);
        if (m<0){printf("enc fail %d %zu\n",f,n); continue;}
        char *t2=malloc((size_t)m?m:1); memcpy(t2,t,(size_t)m);
        uint8_t *o=malloc(zuid_dec_max_len((size_t)m)); long r=zuid_decode(f,t2,(size_t)m,NULL,(long)n,o);
        if (r!=(long)n || memcmp(o,b,n)) printf("BIG roundtrip fail form %d n %zu r %ld\n",f,n,r);
        free(b);free(t);free(t2);free(o); calls++;
    }
    printf("big done %ld\n",calls); fflush(stdout);
    /* formats */
    const char *fa[] = {"0123456789abcdefABCDEF-{}urn:id", "0123456789ABCDEFGHJKMNPQRSTVWXYZabcdefghjkmnpqrstvwxyz", "0123456789abcdefghjkmnpqrstvwxyz_", "234567abcdefghijklmnopqrstuvwxyz_",
        "0123456789abcdefghijklmnopqrstuvwxyzABC","0123456789abcdefghijklmnopqrstuvwxyzABC","0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz","0123456789abcdefghijklmnopqrstuv","0123456789abcdefABCDEF","0123456789"};
    for (int f=0; f<10; f++) for (size_t len=0; len<=300; len++) for (int cls=0; cls<40; cls++){
        uint8_t *b=malloc(len?len:1); size_t al=strlen(fa[f]);
        for (size_t i=0;i<len;i++) b[i]= cls%4==3 ? (uint8_t)rnd() : cls%4==2 ? (uint8_t)fa[f][0] : (uint8_t)fa[f][rnd()%al];
        if (f==2 && len>27 && cls%2) b[len-27]='_';
        if (f==3 && len>5 && cls%2) b[4]='_';
        feed((unsigned)f,b,len); calls++;
        /* uuid forms */
        if (f==0) { for (int form=0; form<17; form++){ uint8_t out[ZUID_MAX_WIDTH]; zuid_prefix p; const char *aa=form>=5?alpha[ (int[]){1,2,3,4,5,6,7,8,9,10,11,12}[form-5] ]:fa[0]; size_t aal=strlen(aa);
            uint8_t *c=malloc(len?len:1); for(size_t i=0;i<len;i++) c[i]= cls%4==3?(uint8_t)rnd(): cls%4==2? (uint8_t)"a "[i%2] : (uint8_t)aa[rnd()%aal];
            zuid_fmt_uuid.parse((char*)c,len,form,out,&p); free(c); calls++; } }
        free(b);
    }
    printf("formats done %ld\n",calls); fflush(stdout);
    /* sqids + cid */
    const char *sq="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int li=0; li<nl; li++) { size_t len=lens[li]; if (len>5000) continue; for (int cls=0; cls<30; cls++){
        uint8_t *b=malloc(len+1); b[0]=(uint8_t)rnd(); const char *a = (b[0]%4==0)?sq:(b[0]%4==1)?"abc":(b[0]%4==2)?"0123456789abcdef":"ABCDEFGHIJKLMNOPQRSTUVWXYZ"; size_t al=strlen(a);
        for (size_t i=0;i<len;i++) b[i+1]=(uint8_t)a[rnd()%al];
        feed(0x80,b,len+1); calls++;
        const char *pf="fFbBcCvVtTkKzmMuUQ"; const char *bodya[]={"0123456789abcdef","abcdefghijklmnopqrstuvwxyz234567=","0123456789abcdefghijklmnopqrstuv=","123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-_="};
        if (len>0){ b[0]=(uint8_t)pf[rnd()%18]; const char *ba=bodya[rnd()%5]; size_t bl=strlen(ba); for(size_t i=1;i<len;i++) b[i]=(uint8_t)ba[rnd()%bl]; if (cls%3==0 && len>3){ b[1]= ba[0]; } feed(0x81,b,len); calls++; }
        for (size_t i=0;i<len;i++) b[i]=(uint8_t)rnd(); if (len>4 && cls%2){ b[0]=1; b[1]=0x55; b[2]= cls%4==1?0:0x12; b[3]=(uint8_t)(len-4); if (len-4>127 ) { b[3]=(uint8_t)(0x80|((len-5)&0x7f)); b[4]=(uint8_t)((len-5)>>7);} }
        feed(0x82,b,len); calls++;
        free(b);} }
    printf("done, %ld calls\n", calls); fflush(stdout);
    return 0;
}
