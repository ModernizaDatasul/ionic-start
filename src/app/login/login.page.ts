import { Component, OnInit, AfterViewInit } from '@angular/core';
import { PoPageLoginCustomField, PoPageLoginLiterals } from '@portinari/portinari-templates';

@Component({
    selector: 'app-login',
    templateUrl: 'login.page.html',
    styleUrls: ['login.page.scss'],
})
export class LoginPage implements AfterViewInit {

    constructor() { }

    public alias: PoPageLoginCustomField = {
        property: 'alias',
        placeholder: 'Digite o Alias',
    };

    public literals: PoPageLoginLiterals = {
        loginLabel: 'Usuário',
        passwordLabel: 'Senha'
    };

    login(event) {
        console.log(event);
    }

    ngAfterViewInit() {
        this.addAliasLabel();
    }

    addAliasLabel() {
        const element = document.querySelector('po-input[name=customFieldInput] .po-field-title');
        element.innerHTML = 'Alias';
    }

}
