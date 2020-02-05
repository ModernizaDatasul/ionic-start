import { Component } from '@angular/core';

import { Platform } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen/ngx';
import { StatusBar } from '@ionic-native/status-bar/ngx';

import { MingleService, Configuration } from '@totvs/mingle';
import { environment } from '../environments/environment';
import { timer } from 'rxjs/observable/timer';

@Component({
    selector: 'app-root',
    templateUrl: 'app.component.html',
    styleUrls: ['app.component.scss']
})
export class AppComponent {

    public showSplash = true;

    constructor(
        private platform: Platform,
        private splashScreen: SplashScreen,
        private statusBar: StatusBar,
        private mingleService: MingleService
    ) {
        this.initializeApp();
    }

    initializeApp() {
        this.platform.ready().then(() => {
            this.statusBar.styleBlackTranslucent();
            this.splashScreen.hide();

            timer(3000).subscribe(() => {
                this.showSplash = false;
            });

            this.initializeMingle();
        });
    }

    async initializeMingle() {
        const config = new Configuration();

        config.app_identifier = environment.app_identifier;
        config.environment = environment.environment;
        config.server = environment.server;

        config.modules.crashr = true;
        config.modules.usage_metrics = true;
        config.modules.gateway = true;
        config.modules.web = true;

        this.mingleService.setConfiguration(config);

        await this.mingleService.init();
    }

}
