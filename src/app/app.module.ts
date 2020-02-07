import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouteReuseStrategy } from '@angular/router';

import { IonicModule, IonicRouteStrategy } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen';
import { StatusBar } from '@ionic-native/status-bar';

import { AppComponent } from './app.component';
import { AppRoutingModule } from './app-routing.module';
import { MingleService } from '@totvs/mingle';
import { PoModule } from '@portinari/portinari-ui';
import { PoStorageModule } from '@portinari/portinari-storage';
import { PoSyncModule } from '@portinari/portinari-sync';

@NgModule({
    declarations: [AppComponent],
    entryComponents: [],
    imports: [
        BrowserModule,
        PoSyncModule,
        IonicModule.forRoot(),
        PoStorageModule.forRoot({
            name: 'myApp', // FIXME: Mudar o nome
            storeName: '_myApp', // FIXME: Mudar o nome
            driverOrder: ['lokijs', 'localstorage', 'indexeddb', 'websql']
        }),
        AppRoutingModule,
        PoModule
    ],
    providers: [
        StatusBar,
        SplashScreen,
        MingleService,
        { provide: RouteReuseStrategy, useClass: IonicRouteStrategy },
    ],
    bootstrap: [AppComponent]
})
export class AppModule { }
