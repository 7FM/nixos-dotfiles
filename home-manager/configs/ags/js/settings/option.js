import { CACHE_DIR, readFile, writeFile } from 'resource:///com/github/Aylur/ags/utils.js';
import { exec } from 'resource:///com/github/Aylur/ags/utils.js';
import options from '../options.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';
import { reloadScss } from './scss.js';
import { setupHyprland } from './hyprland.js';

const CACHE_FILE = CACHE_DIR + '/options.json';
const cacheObj = JSON.parse(readFile(CACHE_FILE) || '{}');

export class Opt extends Service {
    static {
        Service.register(this, {}, {
            'value': ['jsobject'],
        });
    }

    #value;
    #scss = '';
    unit = 'px';
    noReload = false;
    persist = false;
    id = '';
    title = '';
    note = '';
    type = '';
    category = '';
    enums = [];

    format = v => v;
    scssFormat = v => v;

    constructor(value, config) {
        super();
        this.#value = value;
        this.defaultValue = value;
        this.type = typeof value;

        if (config)
            Object.keys(config).forEach(c => this[c] = config[c]);

        import('../options.js').then(this.#init.bind(this));
    }

    set scss(scss) { this.#scss = scss; }
    get scss() {
        return this.#scss || this.id
            .split('.')
            .join('-')
            .split('_')
            .join('-');
    }

    #init() {
        getOptions();

        if (cacheObj[this.id] !== undefined)
            this.setValue(cacheObj[this.id]);

        const words = this.id
            .split('.')
            .flatMap(w => w.split('_'))
            .map(word => word.charAt(0).toUpperCase() + word.slice(1));

        this.title ||= words.join(' ');
        this.category ||= words.length === 1
            ? 'General'
            : words.at(0) || 'General';

        this.connect('changed', () => {
            cacheObj[this.id] = this.value;
            writeFile(
                JSON.stringify(cacheObj, null, 2),
                CACHE_FILE,
            );
        });
    }

    get value() { return this.#value; }
    set value(value) { this.setValue(value); }

    setValue(value, reload = false) {
        if (typeof value !== typeof this.defaultValue) {
            console.error(Error(`WrongType: Option "${this.id}" can't be set to ${value}, ` +
                `expected "${typeof this.defaultValue}", but got "${typeof value}"`));
            return;
        }

        if (this.value !== value) {
            this.#value = this.format(value);
            this.changed('value');

            if (reload && !this.noReload) {
                reloadScss();
                setupHyprland();
            }
        }
    }

    reset(reload = false) {
        if (!this.persist)
            this.setValue(this.defaultValue, reload);
    }
}

export function Option(value, config) {
    return new Opt(value, config);
}

export function getOptions(object = options, path = '') {
    return Object.keys(object).flatMap(key => {
        const obj = object[key];
        const id = path ? path + '.' + key : key;

        if (obj instanceof Opt) {
            obj.id = id;
            return obj;
        }

        if (typeof obj === 'object')
            return getOptions(obj, id);

        return [];
    });
}

export function resetOptions() {
    exec(`rm ${CACHE_FILE}`);
    Object.keys(cacheObj).forEach(key => delete cacheObj[key]);
    getOptions().forEach(opt => opt.reset());
}

export function getValues() {
    const obj = {};
    getOptions()
        .filter(opt => opt.category !== 'exclude')
        .forEach(opt => obj[opt.id] = opt.value);
    return JSON.stringify(obj, null, 2);
}

export function apply(config) {
    const obj = typeof config === 'string' ? JSON.parse(config) : config;
    getOptions().forEach(opt => {
        if (obj[opt.id] !== undefined)
            opt.setValue(obj[opt.id]);
    });
}
