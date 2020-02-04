import { Component } from '@angular/core';

import { Platform } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen/ngx';
import { StatusBar } from '@ionic-native/status-bar/ngx';

import { MingleService, Configuration } from '@totvs/mingle';
import { environment } from '../environments/environment';

@Component({
    selector: 'app-root',
    templateUrl: 'app.component.html',
    styleUrls: ['app.component.scss']
})
export class AppComponent {
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
            this.statusBar.styleDefault();
            this.splashScreen.hide();

            this.initializeMingle();
        });
    }

    initializeMingle() {
        const config = new Configuration();

        config.app_identifier = environment.app_identifier;
        config.environment = environment.environment;
        config.server = environment.server;

        config.modules.crashr = true;
        config.modules.usage_metrics = true;
        config.modules.gateway = true;
        config.modules.push_notification = true;
        config.modules.ocr = false;
        config.modules.web = false;

        this.mingleService.setConfiguration(config);
    }

}
